// Returns a vector that is the DIRECTION mirrored by SURFACE.
// direction: The input which to mirror
// surface: The direction the surface is facing
vector Reflect(vector direction, vector surface)
{
    return (-2 * (direction * surface) * surface + direction);
}

// Handles the entire raycasting sequence.
// pointA: Starting point
// length: Maximum allowed length the ray can travel
// relativeTo: Rotation used for the first ray
// rays: Maximum number of collisions allowed
Cast(vector pointA, float length, rotation relativeTo, integer rays)
{
    // The current ray, with the end-point used for rezzing a marker.
    vector pointB = pointA + <length,0,0>*relativeTo;
    vector contact;
    vector surface;

    do // Cast rays until until collision limit is reached or nothing is hit.
    {
        list data = llCastRay(pointA, pointB,
            [RC_DATA_FLAGS, RC_GET_NORMAL, RC_REJECT_TYPES, RC_REJECT_AGENTS]);
        // llOwnerSay(llList2CSV(data));

        if(llList2Integer(data, -1) > 0) // There was a hit.
        {
            contact = llList2Vector(data, 1);
            surface = llList2Vector(data, 2);

            // Rez visual stuff.
            llRezObject("point", pointA, ZERO_VECTOR, ZERO_ROTATION, 0);
            llRezObject("point", contact, ZERO_VECTOR, ZERO_ROTATION, 0);
            llRezObject("line", pointA, ZERO_VECTOR,
                llRotBetween(<1,0,0>, pointB-pointA),               // Turn X-axis towards B.
                (integer)( llVecDist(pointA, contact) * 20000));    // Give distance as param.
            // llOwnerSay((string)(llVecDist(pointA, contact)*20000));

            // Calculate next ray.
            length = length - llVecDist(pointA, contact);
            // Use the reflected direction of the current ray with new length.
            pointB = pointA + (<length,0,0> * llRotBetween(<1,0,0>, Reflect(pointB-pointA, surface)));
            // Set the new ray's starting point.
            pointA = contact;
        }
        else // No hit, exit function.
        {
            llRezObject("point", pointA, ZERO_VECTOR, ZERO_ROTATION, 0);
            llRezObject("point", pointB, ZERO_VECTOR, ZERO_ROTATION, 0);
            llRezObject("line", pointA, ZERO_VECTOR,
                llRotBetween(<1,0,0>, pointB-pointA),
                (integer)( llVecDist(pointA, pointB)*20000 ));
            return;
        }
    } while (--rays > 0); // loop end
}

default
{
    control(key id, integer held, integer click)
    {
        if(CONTROL_ML_LBUTTON & click & held)
        {
            Cast(llGetCameraPos(), 8.0, llGetCameraRot(), 5);
        }
    }

    state_entry()
    {
        llRequestPermissions(llGetOwner(),
            PERMISSION_TRACK_CAMERA|PERMISSION_TAKE_CONTROLS);
    }

    attach(key id)
    {
        if(id)
        {
            llRequestPermissions(llGetOwner(),
                PERMISSION_TRACK_CAMERA|PERMISSION_TAKE_CONTROLS);
        }
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_TRACK_CAMERA)
        {
            llTakeControls(CONTROL_ML_LBUTTON, 1, 1);
        }
    }
}
