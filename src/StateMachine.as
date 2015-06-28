/**
 * Created by leandro on 6/19/2015.
 */
package {
public class StateMachine {
    public var state:String;
    public var param:Object;
    public var relations:Array = new Array();
    public var eventParam:Object;

    public function StateMachine() {
    }

    public function defineStateRelationWithParam(stateA:String, paramA:Object, stateB:String, paramB:Object, event:String):void{
        relations.push({stateA:stateA, paramA:paramA, stateB:stateB, paramB:paramB, event:event});
    }

    public function defineStateRelation(stateA:String, stateB:String, event:String):void{
        relations.push({stateA:stateA, paramA:null, stateB:stateB, paramB:null, event:event});
    }

    public function dispatchEvent(event:String):void{
        eventParam = null;
        for each(var relation:Object in relations){
            if(relation.stateA == state && (relation.paramA == null || relation.paramA == param) && relation.event == event){
                state = relation.stateB;
                param = relation.paramB;
                return;
            }
        }
        throw new Error("Invalid dispatch " + state + " / " + event);
    }

    public function dispatchEventWithParam(event:String, param:Object):void{
        dispatchEvent(event);
        eventParam = param;
    }


}
}
