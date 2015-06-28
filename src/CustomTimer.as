/**
 * Created by leandro on 6/24/2015.
 */
package {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.TimerEvent;

public class CustomTimer extends EventDispatcher{
    public static var instances:Array = new Array();

    private var currentTime:Number = 0;
    private var currentRepeat:int = 0;
    public var duration:int = 0;
    public var repeat:int = 0;
    public var running:Boolean = false;

    public function CustomTimer(duration:int, repeat:int = 0, autoupdate:Boolean = true) {
        this.duration = duration;
        this.repeat = repeat;
        if(autoupdate) {
            instances.push(this);
        }
    }

    public function start():void{
        running = true;
    }

    public function stop():void{
        running = false;
        currentTime = 0;
        currentRepeat = 0;
    }

    public function pause():void{
        running = false;
    }

    public function update(time:Number):void{
        if(running) {
            currentTime += time;
            if (currentTime >= duration) {
                dispatchEvent(new TimerEvent(TimerEvent.TIMER));
                currentRepeat++;
                currentTime = 0;
                if (currentRepeat >= repeat && repeat != 0) {
                    dispatchEvent(new TimerEvent(TimerEvent.TIMER_COMPLETE));
                    stop();
                }
            }
        }

    }
}
}
