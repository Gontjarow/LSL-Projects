integer group_only = TRUE;

string  note_name = "stations";
integer note_line;

string  station_name = "none";
list    station_names;
list    station_urls;

integer page_num;
integer page_count;

integer ready;
integer menu_channel;
integer input_handle;
key     waiting_from;

show(key avatar, integer page)
{
    integer start = (9 * page) - !!page;
    list menu = ["<<", "URL", ">>"] + llList2List(station_names, start, start + 8);
    llDialog(avatar, "Current station: " + station_name, menu, menu_channel);
}

default
{
    touch_start(integer n)
    {
        if (!ready) return;
        key avatar = llDetectedKey(0);
        if (avatar == llGetOwner() ||               // owner
            !group_only ||                          // anybody
            (group_only && llSameGroup(avatar)))    // any group member
        {
            show(avatar, page_num = 0);
        }
        else llInstantMessage(avatar, "You're not allowed to use this.");
    }

    listen(integer chat, string _, key avatar, string input)
    {
        // Next page with roll-over
        if (input == ">>")
        {
            if (++page_num >= page_count) page_num = 0;
            show(avatar, page_num);
        }
        // Last page with roll-over
        else if (input == "<<")
        {
            if (--page_num < 0) page_num = page_count - 1;
            show(avatar, page_num);
        }
        // Initiate user-input
        else if (input == "URL")
        {
            waiting_from = avatar;
            llListenRemove(input_handle); // Remove previous, if any
            input_handle = llListen(menu_channel + 1, "", avatar, "");
            llTextBox(avatar, "Enter a stream URL", menu_channel + 1);
            llSetTimerEvent(30);
        }
        // Parse user-input
        else if (chat == menu_channel + 1)
        {
            if (llSubStringIndex(input, ".") == -1)
            {
                llInstantMessage(avatar, "I don't think that's a real URL.");
                return;
            }
            if (llSubStringIndex(input, "://") == -1)
            {
                input = "http://" + input;
            }

            station_name = "custom choice";
            llSetParcelMusicURL(input);
            llInstantMessage(avatar, "Now listening to \"" + station_name + "\"");
            llListenRemove(input_handle);
            waiting_from = NULL_KEY;
            llSetTimerEvent(0);
        }
        else
        {
            integer index = llListFindList(station_names, (list)input);
            if (index == -1)
            {
                llInstantMessage(avatar, "That's not on the menu.");
                return;
            }

            station_name = llList2String(station_names, index);
            llSetParcelMusicURL(llList2String(station_urls, index));
            llInstantMessage(avatar, "Now listening to \"" + station_name + "\"");
            llSetTimerEvent(0);
        }
    }

    timer()
    {
        llInstantMessage(waiting_from, "You didn't give a stream URL fast enough.");
        llListenRemove(input_handle);
        waiting_from = NULL_KEY;
        llSetTimerEvent(0);
    }

    // Changed/state_entry/dataserver are only used to initialize the script.
    // The main functionality is in touch_start/listen/timer.
    changed(integer change)
    {
        if (change & CHANGED_OWNER ||
            change & CHANGED_INVENTORY)
            llResetScript();
    }

    state_entry()
    {
        if (llGetInventoryType(note_name) == INVENTORY_NOTECARD)
        {
            llOwnerSay("Loading stations...");
            llGetNotecardLine(note_name, note_line);
        }
        else llOwnerSay("No \"" + note_name + "\" notecard found.");
    }

    // Parse a notecard in this format:
    // Menu button name;Station stream url
    dataserver(key id, string data)
    {
        if (data == EOF)
        {
            page_count = 1 + llGetListLength(station_urls) / 9;
            menu_channel = (integer)("0x" + llGetSubString(llGetKey(), 0, 7));
            llListen(menu_channel, "", "", "");
            ready = TRUE;
            llOwnerSay((string)llGetListLength(station_urls) + " stations added.");
        }
        else
        {
            string first = llGetSubString(data, 0, 0);
            if (first != "#" && first != "")
            {
                integer separator = llSubStringIndex(data, ";");
                if (separator == -1)
                {
                    llOwnerSay("Missing \";\" on line " + (string)(note_line + 1));
                    llGetNotecardLine(note_name, ++note_line);
                    return;
                }

                string button = llGetSubString(data, 0, separator - 1);
                button = llGetSubString(button, 0, 11);

                string url = llGetSubString(data, separator + 1, -1);
                if (llSubStringIndex(url, "://") == -1) url = "http://" + url;

                station_names += button;
                station_urls += url;
            }
            llGetNotecardLine(note_name, ++note_line);
        }
    }
}
