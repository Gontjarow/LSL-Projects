vector World2HUD(vector region_pos)
{
    vector   cam_pos = llGetCameraPos();
    rotation cam_rot = llGetCameraRot();

    // Calculate the offset from camera to region_pos.
    // Positive X is the forward-distance to region_pos.
    // Y0 & Z0 are at the center of the screen.
    // +Y is left, +Z is up; when the HUD is at ZERO_ROTATION.
    vector relative = (region_pos - cam_pos) / cam_rot;

    vector hud;
    if (relative.x > 0) // Ahead of the camera
    {
        // "Perspective division"
        // Here, the forward-distance is used to divide the
        // two other components to "map" them to a lower dimension. (3D -> 2D)
        hud.y = relative.y / relative.x;
        hud.z = relative.z / relative.x;
    }
    return (hud * 0.87); // FOV ratio fix. ZERO_VECTOR if behind the camera.
}
