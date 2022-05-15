// myextension.cpp
// Extension lib defines
#define LIB_NAME "BioSim"
#define MODULE_NAME "biosim"

// include the Defold SDK
#include <dmsdk/sdk.h>

#include <iostream>
#include <sstream>
#include <string>
#include <unordered_map>

// This is included here only for the purpose of unit testing of basic types
#include "basicTypes.h"
#include "peeps.h"
#include "params.h"
#include "signals.h"
#include "imageWriter.h"
#include "simulator.h"
#include "genome-neurons.h"
#include "nodesoup.hpp"

#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

namespace BS {

    static RunMode runMode = RunMode::STOP;
    static Grid grid;        // The 2D world where the creatures live
    static Signals signals;  // A 2D array of pheromones that overlay the world grid
    static Peeps peeps;      // The container of all the individuals in the population
    static ImageWriter imageWriter; // This is for generating the movies

    // The paramManager maintains a private copy of the parameter values, and a copy
    // is available read-only through global variable p. Although this is not
    // foolproof, you should be able to modify the config file during a simulation
    // run and modify many of the parameters. See params.cpp and params.h for more info.
    static ParamManager paramManager;
    const Params &p { paramManager.getParamRef() }; // read-only params

    static unsigned generation  = 0;
    static unsigned survivors   = 0;

    extern uint8_t makeGeneticColor(const Genome &genome);
}

nodesoup::adj_list_t LoadNodeData( BS::lineType lines, std::unordered_map<std::string, nodesoup::vertex_id_t> & names )
{
    nodesoup::adj_list_t g;

    auto name_to_vertex_id = [&g, &names](std::string name) -> nodesoup::vertex_id_t {
        if (name[name.size() - 1] == ';') {
            name.erase(name.end() - 1, name.end());
        }

        nodesoup::vertex_id_t v_id;
        auto it = names.find(name);
        if (it != names.end()) {
            return (*it).second;
        }

        v_id = g.size();
        names.insert({ name, v_id });
        g.resize(v_id + 1);
        return v_id;
    };

    for(int i=0; i<lines.size(); ++i) {
        std::string line = lines[i];
        if (line[0] == '}') {
            break;
        }

        std::istringstream iss(line);
        std::string name, edge_sign, adj_name;
        iss >> name >> edge_sign >> adj_name;

        // add vertex if new
        nodesoup::vertex_id_t v_id = name_to_vertex_id(name);

        assert(edge_sign == "--" || edge_sign.size() == 0);
        if (edge_sign != "--") {
            continue;
        }

        // add adjacent vertex if new

         nodesoup::vertex_id_t adj_id = name_to_vertex_id(adj_name);

        // add edge if new
        if (find(g[v_id].begin(), g[v_id].end(), adj_id) == g[v_id].end()) {
            g[v_id].push_back(adj_id);
            g[adj_id].push_back(v_id);
        }
    }
    return g;
}

void GetGenomeColor(const BS::Indiv &indiv, uint8_t * color)
{
    constexpr uint8_t maxColorVal = 0xb0;
    constexpr uint8_t maxLumaVal = 0xb0;

    auto rgbToLuma = [](uint8_t r, uint8_t g, uint8_t b) { return (r+r+r+b+g+g+g+g) / 8; };

    int c = BS::makeGeneticColor(indiv.genome);
    color[0] = (c);                  // R: 0..255
    color[1] = ((c & 0x1f) << 3);    // G: 0..255
    color[2] = ((c & 7)    << 5);    // B: 0..255

    // Prevent color mappings to very bright colors (hard to see):
    if (rgbToLuma(color[0], color[1], color[2]) > maxLumaVal) {
        if (color[0] > maxColorVal) color[0] %= maxColorVal;
        if (color[1] > maxColorVal) color[1] %= maxColorVal;
        if (color[2] > maxColorVal) color[2] %= maxColorVal;
    }
}


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

    DM_LUA_STACK_CHECK(L,1);
    luaL_checktype(L, 1, LUA_TTABLE);
    luaL_checktype(L, 2, LUA_TTABLE);

    BS::simulationStep();

    int idx = 1;
    
    // We want a copy
    BS::ImageFrameData data = BS::imageWriter.getData();
    
    // // Directly fill the table with the data

    color[0] = color[1] = color[2] = 0x88;

    for (uint16_t index = 1; index <= BS::p.population; ++index) 
    {
        const BS::Indiv &indiv = BS::peeps[index];

        GetGenomeColor(indiv, color);

        lua_pushnumber(L, indiv.loc.x * BS::p.displayScale);
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, ((BS::p.sizeY - indiv.loc.y) - 1) * BS::p.displayScale); 
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, BS::p.agentSize);
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[0]);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[1]);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, color[2]);  
        lua_rawseti(L, 1, idx++); 


        lua_pushnumber(L, indiv.age);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, (int)indiv.alive);  
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, indiv.birthLoc.x * BS::p.displayScale);
        lua_rawseti(L, 1, idx++); 
        lua_pushnumber(L, ((BS::p.sizeY - indiv.birthLoc.y) - 1) * BS::p.displayScale); 
        lua_rawseti(L, 1, idx++); 
    }

    int genidx = 1;
    lua_pushnumber(L, BS::generation);
    lua_rawseti(L, 2, genidx++); 
    lua_pushnumber(L, BS::survivors);
    lua_rawseti(L, 2, genidx++); 
    lua_pushnumber(L, BS::geneticDiversity());
    lua_rawseti(L, 2, genidx++); 

    if(BS::runMode == BS::RunMode::STOP || BS::runMode == BS::RunMode::ABORT)
        idx = 1;
  
    lua_pushnumber(L, idx);
    return 1;
}

//   Get a list of points and lines with weights. This is passed to drawpixels for circles and lines
static int GetAgent(lua_State* L)
{
    DM_LUA_STACK_CHECK(L,0);
    int coordx = luaL_checknumber(L, 1);
    int coordy = luaL_checknumber(L, 2);
    luaL_checktype(L, 3, LUA_TTABLE);   // Agent data
    luaL_checktype(L, 4, LUA_TTABLE);   // Points
    luaL_checktype(L, 5, LUA_TTABLE);   // Names
    luaL_checktype(L, 6, LUA_TTABLE);   // Joins
    int icount = luaL_checknumber(L, 7);
    int k = luaL_checknumber(L, 8);

    // Convert coords back to local corrds for indiv
    BS::Coord     loc;
    loc.x = coordx / BS::p.displayScale;
    loc.y = -((coordy / BS::p.displayScale) + 1 - BS::p.sizeY); 

    loc.x = min(loc.x, BS::grid.sizeX() - 1);
    loc.y = min(loc.y, BS::grid.sizeY() - 1);
    loc.x = max(loc.x, 0);
    loc.y = max(loc.y, 0);

    if(BS::grid.isOccupiedAt(loc)) {
        
        BS::Indiv &indiv = BS::peeps.getIndiv( loc );
        BS::lineType   lines;

        uint8_t color[3];
        GetGenomeColor(indiv, color);

        // Store some agent info in the agent table 
        lua_pushstring(L, "id");
        lua_pushnumber(L, indiv.index );
        lua_rawset(L, 5);
        lua_pushstring(L, "r");
        lua_pushnumber(L, color[0] );
        lua_rawset(L, 5);
        lua_pushstring(L, "g");
        lua_pushnumber(L, color[1] );
        lua_rawset(L, 5);
        lua_pushstring(L, "b");
        lua_pushnumber(L, color[2] );
        lua_rawset(L, 5);
        lua_pushstring(L, "responsiveness");
        lua_pushnumber(L, indiv.responsiveness );
        lua_rawset(L, 5);

        // Get all the neural paths
        indiv.getIGraphEdgeList(&lines);
        // Build a nodesup compatible data set
        std::unordered_map<std::string, nodesoup::vertex_id_t> names;
        nodesoup::adj_list_t list = LoadNodeData( lines, names );

        // List the joins. Simply id <-> id
        for(int i=0; i<list.size(); ++i) {
            if(list[i].size() > 0) {
                for(int j = 0; j<list[i].size(); ++j) {
                    lua_pushnumber(L, i);
                    lua_pushnumber(L, list[i][j]);
                    lua_rawset(L, 6);
                }
            }
        }

        // The list has all the joins of all the nodes. 
        int width = 512;
        int height = 512;

        std::vector<nodesoup::Point2D> results = nodesoup::fruchterman_reingold( list, width, height, icount, k );
        // printf("%d   %d    %d    %d\n", loc.x, loc.y, (int)lines.size(), (int)names.size());
        int idx = 1;
        for(int p = 0; p < results.size(); ++p) {
            lua_pushnumber(L, results[p].x);
            lua_rawseti(L, 3, idx++);
            lua_pushnumber(L, results[p].y);
            lua_rawseti(L, 3, idx++);
        }

        for (auto& it: names) {
            // Do stuff
            // std::cout << it.first << "  " << it.second << std::endl;
            lua_pushnumber(L, it.second);
            lua_pushstring(L, it.first.c_str());
            lua_rawset(L, 4);
        }
    }
    
    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"SimulationStep", SimulationStep},
    {"SimulationStart", SimulationStart},
    {"SimulationMode", SimulationMode },
    {"GetAgent", GetAgent },
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
