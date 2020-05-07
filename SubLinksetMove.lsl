SubLinksetMove(list links, vector target)
{
    list positions;
    integer count = llGetListLength(links);
    integer link;
    
    // Get local positions of all links.
    while(link < count)
    {
        integer prim = llList2Integer(links, link);
        list local_pos = llGetLinkPrimitiveParams(prim, [PRIM_POS_LOCAL]);
        positions += local_pos;
        ++link;
    }
    
    // Get each prim's position relative to the first prim.
    // Must be done in reverse because the first prim's pos is used.
    link = (count - 1);
    while(link >= 0)
    {
        vector primLocal = llList2Vector(positions, link);
        vector primRelative = primLocal - llList2Vector(positions, 0);
        positions = llListReplaceList(positions, [primRelative], link, link);
        --link;
    }
    
    // Start compiling the SLPPF arguments.
    link = 0; list data;
    while(link < count)
    {
        data += [PRIM_LINK_TARGET, llList2Integer(links, link),
                 PRIM_POS_LOCAL, target + llList2Vector(positions, link)];
        ++link;
    }
    
    llSetLinkPrimitiveParamsFast(1, data); // Do the thing!
}

// Demonstration
vector dir = <0.5, 0, 0>;

default
{
    state_entry()
    {
        llSetTimerEvent(0.05);
    }
    
    timer()
    {
        SubLinksetMove([2, 3, 4, 5], dir * llEuler2Rot(<0, 0, llGetTime()>));
    }
}
