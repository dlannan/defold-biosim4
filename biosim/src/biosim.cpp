// myextension.cpp
// Extension lib defines
#define LIB_NAME "BioSim"
#define MODULE_NAME "biosim"

// include the Defold SDK
#include <dmsdk/sdk.h>

#include <iostream>

// This is included here only for the purpose of unit testing of basic types
#include "basicTypes.h"
#include "imageWriter.h"
#include "simulator.h"

static int SimulationStart(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    char *data = (char *)luaL_checkstring(L, 1);

    // BS::unitTestBasicTypes(); // called only for unit testing of basic types

    // Start the simulator with optional config filename (default "biosim4.ini").
    // See simulator.cpp and simulator.h.
    BS::simulator(data); 
    return 0;
}

static int SimulationMode(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int mode = luaL_checknumber(L, 1);
    BS::simulationMode(mode);
    return 0;
}

// Run a single biosim simulation step. 
//    Fills table with the current biosim frame
static int SimulationStep(lua_State* L)
{
    uint8_t color[3];

    DM_LUA_STACK_CHECK(L,2);
    luaL_checktype(L, 1, LUA_TTABLE);

    BS::simulationStep();

    int idx = 1;
    
    // We want a copy
    BS::ImageFrameData data = BS::imageWriter.getData();
    
    // // Directly fill the table with the data

    color[0] = color[1] = color[2] = 0x88;

    constexpr uint8_t maxColorVal = 0xb0;
    constexpr uint8_t maxLumaVal = 0xb0;

    auto rgbToLuma = [](uint8_t r, uint8_t g, uint8_t b) { return (r+r+r+b+g+g+g+g) / 8; };
    
    for (size_t i = 0; i < data.indivLocs.size(); ++i) {
        int c = data.indivColors[i];
            color[0] = (c);                  // R: 0..255
            color[1] = ((c & 0x1f) << 3);    // G: 0..255
            color[2] = ((c & 7)    << 5);    // B: 0..255

            // Prevent color mappings to very bright colors (hard to see):
            if (rgbToLuma(color[0], color[1], color[2]) > maxLumaVal) {
                if (color[0] > maxColorVal) color[0] %= maxColorVal;
                if (color[1] > maxColorVal) color[1] %= maxColorVal;
                if (color[2] > maxColorVal) color[2] %= maxColorVal;
            }

        // image.draw_circle(
        //         data.indivLocs[i].x * p.displayScale,
        //         ((p.sizeY - data.indivLocs[i].y) - 1) * p.displayScale,
        //         p.agentSize,
        //         color,  // rgb
        //         1.0);  // alpha
        lua_pushnumber(L, data.indivLocs[i].x * BS::p.displayScale);
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, ((BS::p.sizeY - data.indivLocs[i].y) - 1) * BS::p.displayScale); 
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, BS::p.agentSize);
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[0]);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[1]);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[2]);  
        lua_rawseti(L, 1, idx++); 
    }

    if(BS::runMode == BS::RunMode::STOP || BS::runMode == BS::RunMode::ABORT)
        idx = 1;
    lua_pushnumber(L, idx);
    lua_pushnumber(L, BS::generation);
    return 2;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"SimulationStep", SimulationStep},
    {"SimulationStart", SimulationStart},
    {"SimulationMode", SimulationMode },
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result AppInitializeMyExtension(dmExtension::AppParams* params)
{
    dmLogInfo("AppInitializeMyExtension");
    return dmExtension::RESULT_OK;
}

static dmExtension::Result InitializeMyExtension(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeMyExtension(dmExtension::AppParams* params)
{
    dmLogInfo("AppFinalizeMyExtension");
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeMyExtension(dmExtension::Params* params)
{
    dmLogInfo("FinalizeMyExtension");
    BS::simulationDone();
    return dmExtension::RESULT_OK;
}

static dmExtension::Result OnUpdateMyExtension(dmExtension::Params* params)
{
    // dmLogInfo("OnUpdateMyExtension");
    return dmExtension::RESULT_OK;
}

static void OnEventMyExtension(dmExtension::Params* params, const dmExtension::Event* event)
{
    switch(event->m_Event)
    {
        case dmExtension::EVENT_ID_ACTIVATEAPP:
            dmLogInfo("OnEventMyExtension - EVENT_ID_ACTIVATEAPP");
            break;
        case dmExtension::EVENT_ID_DEACTIVATEAPP:
            dmLogInfo("OnEventMyExtension - EVENT_ID_DEACTIVATEAPP");
            break;
        case dmExtension::EVENT_ID_ICONIFYAPP:
            dmLogInfo("OnEventMyExtension - EVENT_ID_ICONIFYAPP");
            break;
        case dmExtension::EVENT_ID_DEICONIFYAPP:
            dmLogInfo("OnEventMyExtension - EVENT_ID_DEICONIFYAPP");
            break;
        default:
            dmLogWarning("OnEventMyExtension - Unknown event id");
            break;
    }
}

// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// MyExtension is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(BioSim, LIB_NAME, AppInitializeMyExtension, AppFinalizeMyExtension, InitializeMyExtension, OnUpdateMyExtension, OnEventMyExtension, FinalizeMyExtension)