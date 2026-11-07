import android.content.Context;
import android.database.ContentObserver;
import android.hardware.display.DisplayManager;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.provider.Settings;
import android.view.Display;
import java.lang.reflect.Method;

public final class Fixed144Events {
    private static Handler handler;
    private static PowerManager power;
    private static DisplayManager displays;
    private static int lastDisplayState = -1;
    private static boolean lastAwake;
    private static final Runnable task = () -> { if (power.isInteractive()) emit("TASK"); };
    private static final Runnable settings = () -> emit("SETTINGS");
    private static void emit(String event) {
        System.out.println(event);
        System.out.flush();
    }
    private static void updateState(boolean initial) {
        boolean awake = power.isInteractive();
        if (initial || awake != lastAwake) {
            lastAwake = awake;
            emit(awake ? "AWAKE" : "SLEEP");
            if (awake) {
                for (int delay : new int[]{1000, 3000, 6000}) {
                    handler.postDelayed(() -> {
                        if (power.isInteractive()) emit("SETTLE");
                    }, delay);
                }
            }
        }
        Display display = displays.getDisplay(Display.DEFAULT_DISPLAY);
        int state = display == null ? Display.STATE_UNKNOWN : display.getState();
        if (state != lastDisplayState) {
            lastDisplayState = state;
            if (state == Display.STATE_DOZE_SUSPEND) emit("DOZE_SUSPEND");
        }
    }
    public static void main(String[] args) throws Exception {
        Looper.prepareMainLooper();
        handler = new Handler(Looper.getMainLooper());
        Class<?> threadClass = Class.forName("android.app.ActivityThread");
        Object thread = threadClass.getMethod("systemMain").invoke(null);
        Context context = (Context) threadClass.getMethod("getSystemContext").invoke(thread);
        power = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        displays = (DisplayManager) context.getSystemService(Context.DISPLAY_SERVICE);
        displays.registerDisplayListener(new DisplayManager.DisplayListener() {
            public void onDisplayAdded(int id) { if (id == 0) updateState(false); }
            public void onDisplayRemoved(int id) { if (id == 0) updateState(false); }
            public void onDisplayChanged(int id) { if (id == 0) updateState(false); }
        }, handler);
        Object activityTasks = Class.forName("android.app.ActivityTaskManager")
                .getMethod("getService").invoke(null);
        android.app.TaskStackListener tasks = new android.app.TaskStackListener() {
            @Override public void onTaskStackChanged() {
                handler.removeCallbacks(task);
                handler.postDelayed(task, 200);
            }
        };
        Method register = activityTasks.getClass().getMethod("registerTaskStackListener",
                Class.forName("android.app.ITaskStackListener"));
        register.invoke(activityTasks, tasks);
        ContentObserver observer = new ContentObserver(handler) {
            @Override public void onChange(boolean selfChange) {
                handler.removeCallbacks(settings);
                handler.postDelayed(settings, 300);
            }
        };
        for (String key : new String[]{"vivo_ltpo_setting", "min_refresh_rate", "peak_refresh_rate"}) {
            context.getContentResolver().registerContentObserver(Settings.System.getUriFor(key), false, observer);
        }
        emit("READY");
        updateState(true);
        Looper.loop();
    }
}
