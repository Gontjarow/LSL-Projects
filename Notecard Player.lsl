// For reading the notecard:
string  notecardName;
integer notecardLine;
key     notecardRequest;

// For playing a song:
list    soundList       = []; // all clips
integer soundCurrent    = 0;  // current clip
float   soundDelay      = 0;  // timer until next clip
float   soundVolume     = 1;  // duh

// For playing all songs:
integer songAutoplay    = 0; // move to next song when current one ends
integer songCount       = 0; // inventory notecard count, 0 is user manual!
integer songCurrent     = 0; // tracking for autoplay


PlayNextSoundOrSong()
{
    // Play next sound, then increment for the next clip.
    llPlaySound(llList2String(soundList, soundCurrent++), soundVolume);
    
    // If the next clip is past the end of the song..
    if(soundCurrent >= llGetListLength(soundList))
    {
        if(songAutoplay) // Start loading the next song.
        {
            LoadFromNotecard(++songCurrent);
            return;
        }
        else soundCurrent = 0; // Or loop the current song.
    }
    
    // Note: Preload is limited by distance and is somewhat unreliable.
    llPreloadSound(llList2String(soundList, soundCurrent));
}

LoadFromNotecard(integer inventoryNum)
{
    StopAndCleanUp();
    
    // Range-validity check (Inventory is 0-based but 0 is the "info" notecard)
    if(inventoryNum >= llGetInventoryNumber(INVENTORY_NOTECARD)) inventoryNum = 1;
    else if(inventoryNum < 1) inventoryNum = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
    
    songCurrent = inventoryNum;
    notecardName = llGetInventoryName(INVENTORY_NOTECARD, inventoryNum);
    notecardRequest = llGetNotecardLine(notecardName, notecardLine);
    llOwnerSay("Loading: "+ notecardName +" ("+ (string)inventoryNum +")");
}

StopAndCleanUp()
{
   llSetText("", <1,1,1>, 1);
   llSetTimerEvent(0);
   llStopSound();
   soundList    = [];
   soundCurrent = 0;
   notecardLine = 0;
}

default
{
    state_entry()
    {
        StopAndCleanUp();
        llListen(1, "", llGetOwner(), "");
        songCount = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
        
        // Allows up to 2 sounds be queued for play. (current and ONE awaiting to be played)
        // Prevents skipping when llPlaySound is used before the currently playing sound has ended.
        // The next sound (but only one) will always be kept queued. (adding more sounds to queue will be discarded)
        llSetSoundQueueing(TRUE);
    }
    
    dataserver(key current_query, string data)
    {
        if(data != EOF) // Read until End Of File
        {
            if(notecardLine) // Reading sound UUIDs.
            {
                // Start preloading the first sound already to avoid silence.
                if(notecardLine == 1) llPreloadSound(data);
                soundList += [data];
            }
            else soundDelay = (float)data; // Reading the first line. (time)
            
            // Move onto the next line.
            notecardRequest = llGetNotecardLine(notecardName, ++notecardLine);
        }
        else // End of File
        {
            llSetTimerEvent(soundDelay - 0.01);
            llSetText(notecardName, <1,1,1>, 1.0);
            PlayNextSoundOrSong();
        }
    }
    
    timer()
    {
        PlayNextSoundOrSong();
    }
    
    listen(integer c, string n, key id, string m)
    {
        // Play a random song.
        if(m == "random")
        {
            LoadFromNotecard(llFloor(llFrand(llGetInventoryNumber(INVENTORY_NOTECARD))));
        }
        
        // Play the n-th song, based on its position in the inventory.
        // This check MUST be done before the "play" check to avoid bugs.
        else if(llGetSubString(m,0,5) == "playid" || llGetSubString(m,0,5) == "songid")
        {
            string inputNumberStr = llGetSubString(m,7,-1);
            if(inputNumberStr != "0" && !(integer)inputNumberStr)
            {
                llOwnerSay("ID must be a number!");
                return;
            }
            
            if((integer)inputNumberStr >= llGetInventoryNumber(INVENTORY_NOTECARD))
                 LoadFromNotecard(llGetInventoryNumber(INVENTORY_NOTECARD)-1);
            else LoadFromNotecard((integer)inputNumberStr);
        }
        
        // Play a specific song.
        else if(llGetSubString(m,0,3) == "play" || llGetSubString(m,0,3) == "song")
        {
            // Get the song name. (rest of the message)
            string inputName = llGetSubString(m,5,-1);
            // If the name is found in the object's inventory..
            if(llGetInventoryType(inputName) == INVENTORY_NOTECARD)
            {
                StopAndCleanUp();
                
                // Loop through inventory until a matching name is found.
                integer inventoryNum;
                while(llGetInventoryName(INVENTORY_NOTECARD, inventoryNum) != inputName) { ++inventoryNum; }
                songCurrent = inventoryNum;
                
                // Save the notecard name and start reading.
                notecardRequest = llGetNotecardLine(notecardName = inputName, notecardLine);
                llOwnerSay("Loading.");
            }
            else llOwnerSay("Invalid name!");
        }
        
        // Play the next song.
        else if (llGetSubString(m, 0, 3) == "next")
        {
            LoadFromNotecard(++songCurrent);
        }
        
        // Play the last song.
        else if (llGetSubString(m, 0, 3) == "last")
        {
            LoadFromNotecard(--songCurrent);
        }
        
        // Stop the song.
        else if(m == "stop")
        {
            StopAndCleanUp();
        }
        
        else if(llGetSubString(m,0,3) == "find")
        {
            string inputSearch = llGetSubString(m, 5, -1);
            list matches;
            
            llOwnerSay("Searching for songs with \"" + inputSearch + "\"");
            integer i = llGetInventoryNumber(INVENTORY_NOTECARD)-1;
            while(i--)
            {
                if(~llSubStringIndex(llGetInventoryName(INVENTORY_NOTECARD, i), inputSearch))
                    matches += llGetInventoryName(INVENTORY_NOTECARD, i);
            }
            
            llOwnerSay("Found: " + llList2CSV(matches));
        }
        
        // Set the volume.
        else if(llGetSubString(m,0,2) == "vol") // New short chat command
        {
            // Check for old longer command to take volume value from the right place.
            // Get the value, divide to scale it roughly within the range of 0.0-1.0
            if(llGetSubString(m,3,5) == "ume") //      ┏━ Notice here
                 soundVolume = (float)llGetSubString(m,7,-1)/100;
            else soundVolume = (float)llGetSubString(m,4,-1)/100;
            
            // Correct large numbers (only necessary for OwnerSay display)
            if(soundVolume > 1) soundVolume = 1;
            // Set the new volume.
            llAdjustSoundVolume(soundVolume);
            // Type-cast to integer to truncate decimals for cleaner display.
            llOwnerSay("Volume: "+ (string)((integer)(soundVolume*100)) +"%");
        }
        
        // Toggle autoplay
        else if(llGetSubString(m,0,7) == "autoplay")
        {
            string inputState = llGetSubString(m,9,-1);
            // Set autoplay and display confirmation.
            if(inputState == "on")
            {
                songAutoplay = 1;
                llOwnerSay("Autoplay enabled.");
            }
            else if(inputState == "off")
            {
                songAutoplay = 0;
                llOwnerSay("Autoplay disabled.");
            }
            else llOwnerSay("Invalid command. (on/off)");
        }
        else if(llGetSubString(m,0,3) == "help")
        {
            llOwnerSay("\nThere should also be an included \"info\" notecard in the contents!"
                + "\n\nCurrently usable chat commands:"
                + "\nrandom"
                + "\nfind [partial name]"
                + "\nplay [notecard name]"
                + "\nplayid [inventory number]"
                + "\nstop"
                + "\nautoplay [on/off]"
                + "\nvol [0-100]");
        }
    }
    
    on_rez(integer param)
    {
        StopAndCleanUp();
    }
    
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }
}
