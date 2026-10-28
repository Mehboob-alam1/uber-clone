package in.appyflow.geofire;

import android.util.Log;


import androidx.annotation.NonNull;

import com.firebase.geofire.GeoFire;
import com.firebase.geofire.GeoLocation;
import com.firebase.geofire.GeoQuery;
import com.firebase.geofire.GeoQueryEventListener;
import com.firebase.geofire.LocationCallback;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;

import java.util.ArrayList;
import java.util.HashMap;


import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * GeofirePlugin
 */
public class GeofirePlugin implements FlutterPlugin,MethodCallHandler, EventChannel.StreamHandler {

    GeoFire geoFire;
    DatabaseReference databaseReference;
    static MethodChannel channel;
    static EventChannel eventChannel;
    private EventChannel.EventSink events;

    /**
     * Plugin registration.
     */

    private void pluginInit(BinaryMessenger messenger){
        // Use this plugin instance so EventChannel/MethodChannel stay attached
        // to the FlutterEngine-registered plugin (fixes MissingPluginException).
        channel = new MethodChannel(messenger, "geofire");
        channel.setMethodCallHandler(this);

        eventChannel = new EventChannel(messenger, "geofireStream");
        eventChannel.setStreamHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {

        Log.i("TAG", call.method.toString());

        if (call.method.equals("GeoFire.start")) {

            databaseReference = FirebaseDatabase.getInstance().getReference(call.argument("path").toString());
            geoFire = new GeoFire(databaseReference);

            if (geoFire.getDatabaseReference() != null) {
                result.success(true);
            } else
                result.success(false);
        } else if (call.method.equals("setLocation")) {

            geoFire.setLocation(call.argument("id").toString(), new GeoLocation(Double.parseDouble(call.argument("lat").toString()), Double.parseDouble(call.argument("lng").toString())), new GeoFire.CompletionListener() {
                @Override
                public void onComplete(String key, DatabaseError error) {

                    if (error != null) {
                        result.success(false);
                    } else {
                        result.success(true);
                    }

                }
            });


        } else if (call.method.equals("removeLocation")) {

            geoFire.removeLocation(call.argument("id").toString(), new GeoFire.CompletionListener() {
                @Override
                public void onComplete(String key, DatabaseError error) {

                    if (error != null) {
                        result.success(false);
                    } else {
                        result.success(true);
                    }

                }
            });


        } else if (call.method.equals("getLocation")) {

            geoFire.getLocation(call.argument("id").toString(), new LocationCallback() {
                @Override
                public void onLocationResult(String key, GeoLocation location) {
                    HashMap<String, Object> map = new HashMap<>();
                    if (location != null) {


                        map.put("lat", location.latitude);
                        map.put("lng", location.longitude);
                        map.put("error", null);

                    } else {


                        map.put("error", String.format("There is no location for key %s in GeoFire", key));

                    }

                    result.success(map);
                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    HashMap<String, Object> map = new HashMap<>();
                    map.put("error", "There was an error getting the GeoFire location: " + databaseError);

                    result.success(map);
                }
            });


        } else if (call.method.equals("queryAtLocation")) {
            geoFireArea(Double.parseDouble(call.argument("lat").toString()), Double.parseDouble(call.argument("lng").toString()), result, Double.parseDouble(call.argument("radius").toString()));
        } else if (call.method.equals("stopListener")) {

            if (geoQuery != null) {
                geoQuery.removeAllListeners();
            }

            result.success(true);
        } else {
            result.notImplemented();
        }
    }

    GeoQuery geoQuery;

    HashMap<String, Object> hashMap = new HashMap<>();


    private void geoFireArea(final double latitude, double longitude, final Result result, double radius) {
        try {

            final ArrayList<String> arrayListKeys = new ArrayList<>();

            if (geoQuery != null) {
                geoQuery.setLocation(new GeoLocation(latitude, longitude), radius);
            } else {
                geoQuery = geoFire.queryAtLocation(new GeoLocation(latitude, longitude), radius);
            }

            geoQuery.addGeoQueryEventListener(new GeoQueryEventListener() {
                @Override
                public void onKeyEntered(String key, GeoLocation location) {
                    arrayListKeys.add(key);
                    // Do not remove listeners if sink is not ready yet — that
                    // permanently kills discovery when query starts too early.
                    if (events == null) {
                        return;
                    }
                    HashMap<String, Object> payload = new HashMap<>();
                    payload.put("callBack", "onKeyEntered");
                    payload.put("key", key);
                    payload.put("latitude", location.latitude);
                    payload.put("longitude", location.longitude);
                    events.success(payload);
                }

                @Override
                public void onKeyExited(String key) {
                    arrayListKeys.remove(key);
                    if (events == null) {
                        return;
                    }
                    HashMap<String, Object> payload = new HashMap<>();
                    payload.put("callBack", "onKeyExited");
                    payload.put("key", key);
                    events.success(payload);
                }

                @Override
                public void onKeyMoved(String key, GeoLocation location) {
                    if (events == null) {
                        return;
                    }
                    HashMap<String, Object> payload = new HashMap<>();
                    payload.put("callBack", "onKeyMoved");
                    payload.put("key", key);
                    payload.put("latitude", location.latitude);
                    payload.put("longitude", location.longitude);
                    events.success(payload);
                }

                @Override
                public void onGeoQueryReady() {
                    if (events == null) {
                        return;
                    }
                    HashMap<String, Object> payload = new HashMap<>();
                    payload.put("callBack", "onGeoQueryReady");
                    payload.put("result", new ArrayList<>(arrayListKeys));
                    events.success(payload);
                }

                @Override
                public void onGeoQueryError(DatabaseError error) {
                    if (events == null) {
                        return;
                    }
                    events.error("Error ", "GeoQueryError", error);
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            result.error("Error ", "General Error", e);
        }
    }

    @Override
    public void onListen(Object o, EventChannel.EventSink eventSink) {
        events = eventSink;
    }

    @Override
    public void onCancel(Object o) {
        if (geoQuery != null) {
            geoQuery.removeAllListeners();
        }
        events = null;
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        pluginInit(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
        if (eventChannel != null) {
            eventChannel.setStreamHandler(null);
        }
    }
}