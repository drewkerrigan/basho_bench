% -------------------------------------------------------------------
%%
%% basho_bench_driver_riakc_pb: Driver for riak protocol buffers client
%%
%% Copyright (c) 2009 Basho Techonologies
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
-module(basho_bench_driver_redis).

-export([new/1,
         run/4]).

-include("basho_bench.hrl").

-record(state, { pid }).

-define(TIMEOUT_GENERAL, 62*1000).

%% ====================================================================
%% API
%% ====================================================================

new(Id) ->
    %% Make sure the path is setup such that we can get at riak_client
    case code:which(eredis) of
        non_existing ->
            ?FAIL_MSG("~s requires eredis module to be available on code path.\n",
                      [?MODULE]);
        _ ->
            ok
    end,

    Ips  = basho_bench_config:get(redis_ips, ["127.0.0.1"]),
    Port  = basho_bench_config:get(redis_port, 6379),
    Targets = basho_bench_config:normalize_ips(Ips, Port),
    {TargetIp, TargetPort} = lists:nth((Id rem length(Targets)+1), Targets),
    ?INFO("Using target ~p:~p for worker ~p\n", [TargetIp, TargetPort, Id]),
    {ok, #state {pid = {TargetIp, TargetPort}}}.

open_connection({TargetIp, TargetPort}) ->
    case eredis:start_link(TargetIp, TargetPort) of
        {ok, Pid} ->
            Pid;
        {error, Reason2} ->
            ?FAIL_MSG("Failed to connect eredis to ~p:~p: ~p\n",
                      [TargetIp, TargetPort, Reason2]),
            open_connection({TargetIp, TargetPort})
    end.

run(get, KeyGen, _ValueGen, State) ->
    Pid = open_connection(State#state.pid),
    Key = integer_to_list(KeyGen()),
    Q = ["GET", Key],
    %% ?INFO("GET: ~p", [Q]),
    case eredis:q(Pid, Q) of
        {ok, _} ->
            {ok, State};
        {error, notfound} ->
            {ok, State};
        {error, disconnected} ->
            run(get, KeyGen, _ValueGen, State);
        {error, Reason} ->
            {error, Reason, State}
    end;
run(put, KeyGen, ValueGen, State) ->
    Pid = open_connection(State#state.pid),
    Q = ["SET", integer_to_list(KeyGen()), binary_to_list(ValueGen())],
    %% ?INFO("PUT: ~p", [Q]),
    case eredis:q(Pid, Q) of
        {ok, <<"OK">>} ->
            {ok, State};
        {error, disconnected} ->
            run(put, KeyGen, ValueGen, State);  % suboptimal, but ...
        {error, Reason} ->
            {error, Reason, State}
    end.


%% ====================================================================
%% Internal functions
%% ====================================================================
