#define PERMISSION_AUTO         0xC14
#define CONTROL_ALL_MOVEMENT    0x33F

#define TIMER       0.05

#define MIN_SPEED   1.0
#define INC_SPEED   0.5
#define MAX_SPEED   85.0

#define VTURN_SPEED 2 * DEG_TO_RAD
#define HTURN_SPEED 2 * DEG_TO_RAD

#define MIN_HEIGHT  5

integer     driver_link;
key         driver;

vector      position;
rotation    direction;
float       speed;

start()
{
    llTakeControls(CONTROL_ALL_MOVEMENT, TRUE, FALSE);
    driver_link = llGetNumberOfPrims();
    position = ZERO_VECTOR;
    direction = ZERO_ROTATION;
    speed = MIN_SPEED;
    llSetTimerEvent(TIMER);
    llOwnerSay("Start");
}

end()
{
    llReleaseControls();
    llSetTimerEvent(0);
    llOwnerSay("End");
}

default
{
    timer()
    {
        position += <speed * llGetAndResetTime(),0,0> * direction;

        float ground_height = llGround(ZERO_VECTOR) + MIN_HEIGHT;
        if (position.z < ground_height)
        {
            position.z = ground_height;
        }

        llSetLinkPrimitiveParamsFast(driver_link, [PRIM_POS_LOCAL, position, PRIM_ROTATION, direction]);
    }

    control(key id, integer held, integer click)
    {
        if (CONTROL_UP & held)
        {
            if ((speed += INC_SPEED) > MAX_SPEED)
            {
                speed = MAX_SPEED;
            }
        }
        else if (CONTROL_DOWN & held)
        {
            if ((speed -= INC_SPEED) < MIN_SPEED)
            {
                speed = MIN_SPEED;
            }
        }

        if (CONTROL_FWD & held)
        {
            direction *= llAxisAngle2Rot(llRot2Left(direction), VTURN_SPEED);
        }
        if (CONTROL_BACK & held)
        {
            direction *= llAxisAngle2Rot(llRot2Left(direction), -VTURN_SPEED);
        }
        if (CONTROL_LEFT & held)
        {
            direction *= llAxisAngle2Rot(<0,0,1>, HTURN_SPEED);
        }
        if (CONTROL_RIGHT & held)
        {
            direction *= llAxisAngle2Rot(<0,0,1>, -HTURN_SPEED);
        }
        if (CONTROL_ROT_LEFT & held)
        {
            direction *= llAxisAngle2Rot(<0,0,1>, HTURN_SPEED);
            // Roll:
            // direction *= llAxisAngle2Rot(llRot2Fwd(direction), VTURN_SPEED);
        }
        if (CONTROL_ROT_RIGHT & held)
        {
            direction *= llAxisAngle2Rot(<0,0,1>, -HTURN_SPEED);
            // Roll:
            // direction *= llAxisAngle2Rot(llRot2Fwd(direction), -VTURN_SPEED);
        }
    }

    run_time_permissions(integer perm)
    {
        if (perm)
        {
            start();
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            if (driver = llAvatarOnSitTarget())
            {
                llRequestPermissions(driver, PERMISSION_AUTO);
            }
            else
            {
                end();
            }
        }
    }

    state_entry()
    {
        llSitTarget(<0,0,1>, ZERO_ROTATION);
        llForceMouselook(TRUE);
    }
}
