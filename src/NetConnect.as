/**
 * Created by leandro on 6/24/2015.
 */
package {
import flash.events.NetStatusEvent;
import flash.net.GroupSpecifier;
import flash.net.NetConnection;
import flash.net.NetGroup;

public class NetConnect {
    private const SERVER:String = "rtmfp://p2p.rtmfp.net/";
    private const DEVKEY:String = "cde41fe05bb01817e82e5398-2ab5d983d09f";
    private var nc:NetConnection;
    public var nearId:String;
    public var farId:String;
    private var sequence:uint = 0;
    private var netGroup:NetGroup;
    private var user:String;
    private var connected:Boolean = false;

    public function NetConnect() {
    }

    public function connect():void{
        nc = new NetConnection();
        nc.addEventListener(NetStatusEvent.NET_STATUS,netStatus);
        nc.connect(SERVER+DEVKEY);
    }


    private function setupGroup():void{
        var groupspec:GroupSpecifier = new GroupSpecifier("myGroup/g1");
        groupspec.serverChannelEnabled = true;
        groupspec.postingEnabled = true;

        trace("Groupspec: "+groupspec.groupspecWithAuthorizations());

        netGroup = new NetGroup(nc,groupspec.groupspecWithAuthorizations());
        netGroup.addEventListener(NetStatusEvent.NET_STATUS,netStatus);


        user = "user"+Math.round(Math.random()*10000);
        trace(user);
    }

    private function netStatus(event:NetStatusEvent):void{
        switch(event.info.code){
            case "NetConnection.Connect.Success":
                setupGroup();
                break;

            case "NetGroup.Connect.Success":
                connected = true;
                Main.instance.stateMachine.dispatchEvent("complete");
                break;

            case "NetGroup.Neighbor.Connect":
                nearId = nc.nearID;
                farId = event.info.peerID;
                Main.instance.stateMachine.dispatchEvent("complete");
                break;

            case "NetGroup.Posting.Notify":
                receiveMessage(event.info.message);
                break;
        }
    }

    public function sendMessage(data:Object):void{
        if(connected) {
            var message:Object = new Object();
            message.sender = netGroup.convertPeerIDToGroupAddress(nc.nearID);
            message.sequence = sequence++;
            message.user = "user";
            message.data = data;
            netGroup.post(message);
        }
    }

    private function receiveMessage(message:Object):void{
        if(connected) {
            switch (message.data.action) {
                case "passTurn":
                    Main.instance.stateMachine.dispatchEvent("passed");
                    break;
                case "lines":
                    for each(var _units:Vector.<UnitView> in Main.instance.units){
                        for each(var unit:UnitView in _units) {
                            if (unit.owner.id == message.data.id) {
                                Main.instance.drawFromBuildingLine(unit, message.data.x, message.data.y);
                                break;
                            }
                        }
                    }
                    break;
                case "place":
                    trace(message.data.x, message.data.y, message.data.type, message.data.team);
                    var player:Player = Main.instance.players[message.data.team];
                    Main.instance.createBuilding(message.data.x, message.data.y, message.data.type, player);
                    break;
            }
        }
    }
}
}
