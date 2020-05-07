integer channel;

list attachments; // UUIDs
integer count;

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }
    
    state_entry()
    {
        channel = (integer)("0x"+llGetSubString(llGetKey(), 0, 7));
        llListen(channel, "", llGetOwner(), "");
    }

    touch_start(integer n)
    {
        if(llDetectedKey(0) != llGetOwner()) return;

        llTextBox( llGetOwner(),
            "\n\nEnter an avatar's name in this sim."
            + " (channel " + (string)channel + ")", channel);
    }

    listen(integer channel, string name, key id, string message)
    {
        if(llName2Key(message)) // avatar is known to this region
        {
            attachments = llGetAttachedList(llName2Key(message));
            if( !(count = llGetListLength(attachments)) )
            {
                llOwnerSay("This weirdo hasn't got a single attachment.");
                return;
            }

            while(count--)
            {
                key attachment = llList2Key(attachments, count);
                string creator = llList2String(llGetObjectDetails(attachment, [OBJECT_CREATOR]), 0);
                string uri = "secondlife:///app/agent/" + creator + "/about";
                llOwnerSay(llKey2Name(attachment) + " " + uri);
            }
        }
        else llOwnerSay("No such avatar here.");
    }
}
