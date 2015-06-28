/**
 * Created by leandro on 6/20/2015.
 */
package {
import flash.display.Sprite;

import starling.display.Sprite;

public class UnitView {
    public var owner:Unit;
    public var view:starling.display.Sprite;
    public var lines:flash.display.Sprite;

    public function UnitView(owner:Unit, view:starling.display.Sprite) {
        this.owner = owner;
        this.view = view;
    }
}
}
