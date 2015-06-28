/**
 * Created by leandro on 6/25/2015.
 */
package {
import flash.display.Sprite;
import flash.display.StageScaleMode;
import flash.events.Event;

import starling.core.Starling;

[SWF(backgroundColor="#100617", width="800", height="600", frameRate="60")]
public class Startup extends Sprite {
    private var starlingInstance:Starling;

    public function Startup() {
        super();
        addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    }

    private function onAddedToStage(e:Event):void{
        stage.frameRate = Main.FPS_GRAPHICS;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

        starlingInstance = new Starling(Main, stage);
        starlingInstance.showStats = true;
        starlingInstance.antiAliasing = 0;
        starlingInstance.start();
    }
}
}
