#!/data/data/com.termux/files/usr/bin/bash
# Termux-ൽ campus-store.html -> CampusStore.apk
set -e
HTML="${1:-$HOME/storage/downloads/campus-store.html}"
W=~/apkbuild
[ -f "$HTML" ] || { echo "HTML ഫയൽ കിട്ടിയില്ല: $HTML"; exit 1; }
for t in aapt2 ecj apksigner zip keytool; do command -v $t >/dev/null || { echo "$t ഇല്ല. ഇത് അടിക്കുക: pkg install -y openjdk-17 aapt2 ecj d8 apksigner zip"; exit 1; }; done
if command -v d8 >/dev/null; then DEX="d8 --release --min-api 24 --no-desugaring --lib \$AJ --output out"; elif command -v dx >/dev/null; then DEX="dx --dex --output=out/classes.dex"; else echo "d8/dx ഇല്ല: pkg install d8"; exit 1; fi
AJ=$(find $PREFIX ~/.android -name 'android.jar' 2>/dev/null | head -1)
[ -n "$AJ" ] || { echo "android.jar കിട്ടിയില്ല (ecj ഇൻസ്റ്റാൾ ചെയ്താൽ വരേണ്ടതാണ്). ഈ സന്ദേശം എനിക്ക് അയക്കൂ."; exit 1; }
echo "android.jar: $AJ"
rm -rf $W; mkdir -p $W/assets $W/src/com/campus/store $W/classes $W/out; cd $W
cp "$HTML" assets/index.html
cat > AndroidManifest.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.campus.store">
  <application android:label="TSQ STORE" android:icon="@drawable/ic_launcher" android:theme="@android:style/Theme.DeviceDefault.NoActionBar">
    <activity android:name=".MainActivity" android:exported="true" android:configChanges="orientation|screenSize|keyboardHidden">
      <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
XML
cat > src/com/campus/store/MainActivity.java <<'JAVA'
package com.campus.store;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.net.Uri;
import android.os.Bundle;
import android.provider.MediaStore;
import android.webkit.*;
import java.io.File;
import java.io.FileOutputStream;

public class MainActivity extends Activity {
  WebView w;
  ValueCallback<Uri[]> fcb;

  @Override protected void onCreate(Bundle b) {
    super.onCreate(b);
    w = new WebView(this);
    setContentView(w);
    WebSettings s = w.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true);
    s.setAllowFileAccess(true);
    w.setWebViewClient(new WebViewClient());
    w.setWebChromeClient(new WebChromeClient() {
      @Override public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams p) {
        if (fcb != null) fcb.onReceiveValue(null);
        fcb = cb;
        try {
          if (p.isCaptureEnabled()) startActivityForResult(new Intent(MediaStore.ACTION_IMAGE_CAPTURE), 2);
          else startActivityForResult(p.createIntent(), 1);
        } catch (Exception e) { fcb = null; return false; }
        return true;
      }
    });
    w.loadUrl("file:///android_asset/index.html");
  }

  @Override protected void onActivityResult(int q, int r, Intent d) {
    if (fcb == null) return;
    Uri[] res = null;
    if (q == 1) {
      res = WebChromeClient.FileChooserParams.parseResult(r, d);
    } else if (q == 2 && r == RESULT_OK && d != null && d.getExtras() != null) {
      try {
        Bitmap bm = (Bitmap) d.getExtras().get("data");
        File f = new File(getCacheDir(), "cam" + System.currentTimeMillis() + ".jpg");
        FileOutputStream o = new FileOutputStream(f);
        bm.compress(Bitmap.CompressFormat.JPEG, 92, o);
        o.close();
        res = new Uri[] { Uri.fromFile(f) };
      } catch (Exception e) { res = null; }
    }
    fcb.onReceiveValue(res);
    fcb = null;
  }
}
JAVA
echo "1/5 manifest + icon + assets"
mkdir -p res/drawable
base64 -d > res/drawable/ic_launcher.png <<'B64'
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
B64
aapt2 compile --dir res -o res.zip
aapt2 link -o base.apk -I /system/framework/framework-res.apk --manifest AndroidManifest.xml --min-sdk-version 24 --target-sdk-version 29 --version-code 4 --version-name 1.3 -A assets res.zip
echo "2/5 java compile"
ecj -proc:none -cp "$AJ" -d classes src/com/campus/store/MainActivity.java
echo "3/5 dex"
eval $DEX "\$(find classes -name \"*.class\")"
echo "4/5 package"
(cd out && zip -q ../base.apk classes.dex)
echo "5/5 sign"
KS=~/campus.keystore
[ -f $KS ] || keytool -genkeypair -keystore $KS -alias campus -keyalg RSA -keysize 2048 -validity 10000 -storepass campus123 -keypass campus123 -dname "CN=CampusStore"
apksigner sign --ks $KS --ks-pass pass:campus123 --key-pass pass:campus123 --out CampusStore.apk base.apk
mkdir -p ~/storage/downloads
cp CampusStore.apk ~/storage/downloads/CampusStore.apk
echo "തയ്യാർ: Downloads/CampusStore.apk"
