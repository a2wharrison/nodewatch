%% -----------------------------------------------------------------------------
%%
%% Erlang System Monitoring Database: Top Level Supervisor
%%
%% Copyright (c) 2008-2010 Tim Watson (watson.timothy@gmail.com)
%%
%% Permission is hereby granted, free of charge, to any person obtaining a copy
%% of this software and associated documentation files (the "Software"), to deal
%% in the Software without restriction, including without limitation the rights
%% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the Software is
%% furnished to do so, subject to the following conditions:
%%
%% The above copyright notice and this permission notice shall be included in
%% all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
%% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
%% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
%% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
%% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
%% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
%% THE SOFTWARE.
%% -----------------------------------------------------------------------------

-module(dxdb_sup).
-author('Tim Watson <watson.timothy@gmail.com>').
-behaviour(supervisor).

-include("../include/types.hrl").

%% API
-export([full_start/0, start_link/0]).
-export([init/1]).

%% ===================================================================
%% API functions
%% ===================================================================

full_start() ->
    mnesia:create_schema([node()]),
    application:start(mnesia, permanent),
    start_link().

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    Children = [
        {dxdb_schema,
            {dxdb_schema, start_link, []},
            temporary, 5000, worker, [gen_server]},
        {dxdb_event_handler, 
            {gen_event, start_link, [{local, dxdb_event_handler}]},
            temporary, 5000, worker, dynamic}
    ],
    {ok, {{one_for_one, 10, 10}, Children}}.
