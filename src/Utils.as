/**
 * Created by leandro on 6/26/2015.
 */
package {

public class Utils {
    public function Utils() {
    }

    public static function deleteUnitView(array:Vector.<UnitView>, i:int){
        var lastElement:UnitView = array.pop();
        if(i < array.length)
            array[i] = lastElement;
    }

    public static function deleteUnit(array:Vector.<Unit>, i:int){
        var lastElement:Unit = array.pop();
        if(i < array.length)
            array[i] = lastElement;
    }

}
}
