/**
 * Created by leandro on 6/26/2015.
 */
package {

public class CustomMath {
    public function CustomMath() {
    }

    public static function getShortestDistance(line1:Object, line2:Object):Number
    {
        line1.z1 = line1.z2 = line2.z1 = line2.z2 =0;

        var EPS:Number = 0.00000001;

        var delta21:Object = new Object();
        delta21.x = line1.x2 - line1.x1;
        delta21.y = line1.y2 - line1.y1;
        delta21.z = line1.z2 - line1.z1;

        var delta41:Object = new Object();
        delta41.x = line2.x2 - line2.x1;
        delta41.y = line2.y2 - line2.y1;
        delta41.z = line2.z2 - line2.z1;

        var delta13:Object = new Object();
        delta13.x = line1.x1 - line2.x1;
        delta13.y = line1.y1 - line2.y1;
        delta13.z = line1.z1 - line2.z1;

        var a:Number = dot(delta21, delta21);
        var b:Number = dot(delta21, delta41);
        var c:Number = dot(delta41, delta41);
        var d:Number = dot(delta21, delta13);
        var e:Number = dot(delta41, delta13);
        var D:Number = a * c - b * b;

        var sc:Number;
        var sN:Number;
        var sD:Number = D;
        var tc:Number;
        var tN:Number;
        var tD:Number = D;

        if (D < EPS)
        {
            sN = 0.0;
            sD = 1.0;
            tN = e;
            tD = c;
        }
        else
        {
            sN = (b * e - c * d);
            tN = (a * e - b * d);
            if (sN < 0.0)
            {
                sN = 0.0;
                tN = e;
                tD = c;
            }
            else if (sN > sD)
            {
                sN = sD;
                tN = e + b;
                tD = c;
            }
        }

        if (tN < 0.0)
        {
            tN = 0.0;

            if (-d < 0.0)
                sN = 0.0;
            else if (-d > a)
                sN = sD;
            else
            {
                sN = -d;
                sD = a;
            }
        }
        else if (tN > tD)
        {
            tN = tD;
            if ((-d + b) < 0.0)
                sN = 0;
            else if ((-d + b) > a)
                sN = sD;
            else
            {
                sN = (-d + b);
                sD = a;
            }
        }

        if (Math.abs(sN) < EPS) sc = 0.0;
        else sc = sN / sD;
        if (Math.abs(tN) < EPS) tc = 0.0;
        else tc = tN / tD;

        var dP:Object = new Object();
        dP.x = delta13.x + (sc * delta21.x) - (tc * delta41.x);
        dP.y = delta13.y + (sc * delta21.y) - (tc * delta41.y);
        dP.z = delta13.z + (sc * delta21.z) - (tc * delta41.z);

        return Math.sqrt(dot(dP, dP));
    }

    private static function dot(c1:Object, c2:Object):Number
    {
        return (c1.x * c2.x + c1.y * c2.y + c1.z * c2.z);
    }

    private static function norm(c1:Object):Number
    {
        return Math.sqrt(dot(c1, c1));
    }
}
}
