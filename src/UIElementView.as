/**
 * Created by leandro on 6/28/2015.
 */
package {
import starling.display.Quad;
import starling.display.Sprite;
import starling.text.TextField;

public class UIElementView {

    public var element:UIElement;
    public var view:Sprite;

    public function UIElementView(element:UIElement) {
        view = new Sprite();
        if(element.w && element.h){
            if(element.color){
                var quad:Quad = new Quad(element.w, element.h, element.color);
                view.addChild(quad);
            } else {
                if(element.image){
                    //init image here
                }
            }
        }
        if(element.text){
            var textField:TextField = new TextField(100, 50, element.text, "Verdana", 12, 0x0, false);
            view.addChild(textField);
        }
        if(element.x && element.y){
            view.x = element.x;
            view.y = element.y;
        }
    }
}
}
