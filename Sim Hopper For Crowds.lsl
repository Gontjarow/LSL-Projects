string QUERY_URL = "http://api.gridsurvey.com/simquery.php?region=";
string RANDOM = "FETCH_RANDOM_ONLINE_REGION_FROM_DATABASE";

key SND_BEEP = "11a3f4d6-75ea-acf3-29a7-41bcba51a9d6";

// Chat commands go here.
integer chat_channel = 1;
// Commands intended for/by scripts only.
integer script_channel = -92403;

// used in TeleportCheck
integer allow_adult = 1;
integer allow_moderate = 0;
integer allow_general = 0;

// init in listen, used in dataserver
// How many tries to find a random server?
integer max_retries = 10;
integer retries_left;

// init in dataserver, used in timer
// Countdown before actually teleporting
integer max_timer = 5;
integer time_left;

key query_sim_name;     // for llHTTPRequest
key query_sim_rating;   // for llRequestSimulatorData
key query_sim_pos;      // for llRequestSimulatorData

// sim info
integer data_received;  // used in dataserver
string target_name;     // from http_response
string target_rating;   // from dataserver
vector target_pos;      // from dataserver

GetSimData(string sim_name)
{
    target_pos = <0,0,0>;
    target_rating = "";
    data_received = 0;
    query_sim_rating = llRequestSimulatorData(sim_name, DATA_SIM_RATING);
    query_sim_pos = llRequestSimulatorData(sim_name, DATA_SIM_POS);
}

integer TeleportCheck(string rating, vector pos)
{
    if(pos == ZERO_VECTOR)
    {
        llOwnerSay("TP failed, invalid coordinates!");
        return 0;
    }
    if( (rating == "ADULT"  && !allow_adult) ||
        (rating == "MATURE" && !allow_moderate) ||
        (rating == "PG"     && !allow_general) ||
        (rating == "UNKNOWN"))
    {
        llOwnerSay("TP failed, invalid maturity rating");
        return 0;
    }
    else return 1;
}

default
{
    listen(integer c, string n, key id, string m)
    {
        if(c == chat_channel)
        {
            if(llToLower(m) == "hop")
            {
                llOwnerSay("Looking for a sim...");
                retries_left = max_retries;
                query_sim_name = llHTTPRequest(QUERY_URL + RANDOM, [], "");
            }
        }
        else if(c == script_channel)
        {
            string cmd = llGetSubString(m, 0, 3);   // first 4 chars
            string data = llGetSubString(m, 4, -1); // the rest
            
            if(cmd == "TICK")
            {
                // llOwnerSay((string)data + "s to TP!");
                llPlaySound(SND_BEEP, 1);
            }
            if(cmd == "TELE")
            {
                target_pos = (vector)data;
                llTeleportAgentGlobalCoords(llGetOwner(), target_pos, <128, 128, 64>, <0,0,0>);
            }
        }
    }
    
    http_response(key request, integer status, list metadata, string body)
    {
        if(request == query_sim_name)
        {
            GetSimData(target_name = body);
        }
    }
    
    dataserver(key request, string data)
    {
        if(request == query_sim_rating)
        {
            target_rating = data;
            query_sim_rating = NULL_KEY;
            ++data_received;
        }
        else if(request == query_sim_pos)
        {
            target_pos = (vector)data;
            query_sim_pos = NULL_KEY;
            ++data_received;
        }
        
        // Dataserver requests may not be answered in order..
        // so we keep count of how many responses we've got.
        if(data_received == 2)
        {
            // Let's check whether the target sim meets our criteria.
            if(!TeleportCheck(target_rating, target_pos))
            {
                // If not, and we still have retries left, try again.
                if(retries_left--)
                     query_sim_name = llHTTPRequest(QUERY_URL + RANDOM, [], "");
                else llOwnerSay("Giving up on retries!");
            }
            else
            {
                // If the sim passes our criteria, start the countdown timer.
                llOwnerSay("Found a sim!");
                time_left = max_timer;
                llSetTimerEvent(1);
                query_sim_name = NULL_KEY;
            }
        }
    }
    
    timer() // Just beep beep like a sheep until teleport.
    {
        if(--time_left)
        {
            llPlaySound(SND_BEEP, 1);
            llRegionSay(script_channel, "TICK" + (string)time_left);
            // llOwnerSay((string)time_left + "s to TP!");
        }
        else
        {
            llSetTimerEvent(0);
            llRegionSay(script_channel, "TELE" + (string)target_pos);
            llTeleportAgentGlobalCoords(llGetOwner(), target_pos, <128, 128, 64>, <0,0,0>);
        }
    }
    
    state_entry()
    {
        llListen(chat_channel, "", llGetOwner(), "");   // for chat commands
        llListen(script_channel, "", "", "");           // for scripts
        
        llRequestPermissions(llGetOwner(),              // cheat no-script areas
            PERMISSION_TELEPORT|PERMISSION_TAKE_CONTROLS);
    }
    
    attach(key id)
    {
        if(id) llRequestPermissions(llGetOwner(),
            PERMISSION_TELEPORT|PERMISSION_TAKE_CONTROLS);
    }
    
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }
}
