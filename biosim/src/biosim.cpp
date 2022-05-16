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
#include "nodesoup.hpp"

#define min(a,b) ((a)<(b)?(a):(b))
#define max(a,b) ((a)>(b)?(a):(b))

std::vector<std::string> split(std::string str, std::string token)
{
    std::vector<std::string>result;
    while(str.size()){
        int index = str.find(token);
        if(index!=std::string::npos){
            result.push_back(str.substr(0,index));
            str = str.substr(index+token.size());
            if(str.size()==0)result.push_back(str);
        }else{
            result.push_back(str);
            str = "";
        }
    }
    return result;
}

nodesoup::adj_list_t LoadNodeData( const char * linedata, std::unordered_map<std::string, nodesoup::vertex_id_t> & names )
{
    nodesoup::adj_list_t g;
    std::string page(linedata);
    std::vector<std::string> lines = split(page, "\n");

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

//   Get a list of points and lines with weights. This is passed to drawpixels for circles and lines
static int GetAgent(lua_State* L)
{
    DM_LUA_STACK_CHECK(L,0);
    const char * linedata = luaL_checkstring(L, 1);
    luaL_checktype(L, 2, LUA_TTABLE);   // Points
    luaL_checktype(L, 3, LUA_TTABLE);   // Names
    luaL_checktype(L, 4, LUA_TTABLE);   // Joins
    int icount = luaL_checknumber(L, 5);
    int k = luaL_checknumber(L, 6);

    // Build a nodesup compatible data set
    std::unordered_map<std::string, nodesoup::vertex_id_t> names;
    nodesoup::adj_list_t list = LoadNodeData( linedata, names );

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
    
    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
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
