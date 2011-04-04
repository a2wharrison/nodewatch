%% -----------------------------------------------------------------------------
%%
%% Erlang System Monitoring Database: API
%%
%% Copyright (c) 2010 Tim Watson (watson.timothy@gmail.com)
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
%% @author Tim Watson [http://hyperthunk.wordpress.com]
%% @copyright (c) Tim Watson, 2010
%% @since: March 2010
%%
%% @doc External API for the database application.
%%
%% -----------------------------------------------------------------------------
-module(dxdb).
-author('Tim Watson <watson.timothy@gmail.com>').
-export([add_user/2
        ,check_user/2
        ,remove_subscriptions/1]).

-include("../include/types.hrl").

%%
%% @doc Adds a user to the database.
%%
-spec(add_user(username(), string()) -> ok | {error, term()}).
add_user(Name, Password) ->
    <Digest:160> = crypto:sha(Password),
    write(#user{name=Name, password=Digest}).

subscribe_user(User, Sensor, Mode) ->
    Write = 
        fun() ->
            mnesia:write_lock_table(subscription),
            ID = case mnesia:table_info(subscription, size) == 0 of
                true ->  1;
                false -> mnesia:last(subscription)
            end,
            mnesia:write(#subscription{id = 1,  
                                       user = User,
                                       mode = Mode,
                                       sensor = Sensor})
        end
    transaction(Write).

%%
%% @doc Checks a user name and password against the database.
%%
-spec(check_user(username(), string()) -> true | false).
check_user(Name, Password) ->
    <Digest:160> = crypto:sha(Password),
    Found = qlc:q([X#user.name || X <- mnesia:table(user), 
                                  X#user.name == Name, 
                                  X#user.password == Digest]),
    length(Found) == 1.

write(Item) ->
    transaction(fun() -> mnesia:write(Item) end).

transaction(Fun)
    case mnesia:transaction(Fun) of
        {atomic, _} ->
            ok;
        {aborted, Reason} ->
            {error, Reason}
    end
