
#define GS_AUDIO_IMPL_CUSTOM
#define GS_NO_HIJACK_MAIN
#define GS_IMPL

#define GS_IMMEDIATE_DRAW_IMPL
#define GS_GUI_IMPL

#include "gs_impl.h"



bool32 gs_app_is_running()
{
    return gs_app()->is_running;
}

int hello_from_c()
{
    gs_println("printing from C");
    return 123;
}
