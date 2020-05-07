integer open;
integer open_deg = 90;
integer open_time = 5;
rotation rot_closed;

default
{
    state_entry()
    {
        // Sets up the object in the way required by this script. (Half-cut box)
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_TYPE, PRIM_TYPE_BOX,
            0, <0.375, 0.875, 0>, 0, ZERO_VECTOR, <1,1,0>, ZERO_VECTOR
        ]);
        rot_closed = llGetLocalRot();
    }

    touch_start(integer n)
    {
        if(open) return; // Ignore clicks while open.

        vector avatar_position = llDetectedPos(0);
        vector avatar_direction = llVecNorm(avatar_position - llGetPos()) / llGetRot();
        llOwnerSay((string)avatar_direction);

        // Assumes the front face (1) of the door is towards the outside.
        if( avatar_direction.x > 0 )
        {
            llOwnerSay("Welcome!");
            llSetLocalRot(llGetLocalRot() * llEuler2Rot(<0,0,open_deg*DEG_TO_RAD>));
        }
        else
        {
            llOwnerSay("Goodbye!");
            llSetLocalRot(llGetLocalRot() * llEuler2Rot(<0,0,-open_deg*DEG_TO_RAD>));
        }

        open = TRUE;
        llSetTimerEvent(open_time);
    }

    timer()
    {
        llSetLocalRot(rot_closed);
        open = FALSE;
        llSetTimerEvent(0);
    }
}
