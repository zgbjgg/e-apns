%% ==============================================================================
%
% This module implements the manage & connection of a ssl socket to APNS server,
% also provide methods to push notifications and recevie responses.
%
% Copyright (c) 2013 Jorge Garrido <jorge.garrido@morelosoft.com>.
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
% 3. Neither the name of copyright holders nor the names of its
%    contributors may be used to endorse or promote products derived
%    from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
% TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
% PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COPYRIGHT HOLDERS OR CONTRIBUTORS
% BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%% ===============================================================================
-module('e-apns').

-behaviour(gen_server).

%% API
-export([start_link/0, stop/0, get_loaded_resource/0, get_resource_apns/0, push_apns/5]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-include("e-apns.hrl").

-record(state, {ssl_alive=[], address, port, options, timeout}).

%%%===================================================================
%%% API
%%%===================================================================

get_loaded_resource() ->
    gen_server:call(?MODULE, loaded_resource).

get_resource_apns() ->
    gen_server:call(?MODULE, resource_apns, 10000).

push_apns(Resource, Identifier, Expiry, Token, {Alert, Sound, Badge}) ->
    Packet = 'e-apns_u':packet(Identifier, Expiry, 'e-apns_u':hex_token(Token), 'e-apns_u':payload(Alert, Sound, Badge)),
    gen_server:cast(?MODULE, {push_apns, Packet, Resource}). 

stop() ->
    gen_server:call(?MODULE, stop).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initiates the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    process_flag(trap_exit, true),
    Ebin = filename:dirname(code:which('e-apns')),
    Config = filename:join(filename:dirname(Ebin), "priv") ++ "/e-apns.config",    
    case file:consult(Config) of
	{error, FileError} ->
            io:format("I(~p) [e-apns] apns error to initialize: ~p \n", [self(), FileError]),
	    {stop, FileError};
        {ok, Args}         ->
	    [Address, Port, CertFile, KeyFile, Password, Timeout] = 
		[ proplists:get_value(Tag, Args) || Tag <- ?TAGS ],
	    Options = [{certfile, CertFile}, {keyfile, KeyFile}, {password, Password}, {mode, binary}],	    
	    io:format("I(~p) [e-apns] apns initialized\n", [self()]),
            {ok, #state{ssl_alive=[], address=Address, port=Port, options=Options, timeout=Timeout}}
    end.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(loaded_resource, _From, State=#state{ssl_alive=[], address=_Address, port=_Port,
                                                        options=_Options, timeout=_Timeout}) ->
    {reply, {ok, unset}, State};
handle_call(loaded_resource, _From, State=#state{ssl_alive=[{SslSocket, From}|_], address=_Address, port=_Port,
							options=_Options, timeout=_Timeout}) ->
    {reply, {ok, {ok, SslSocket, From}}, State};
handle_call(resource_apns, {From, _Ref}, State=#state{ssl_alive=Alive, address=Address, port=Port,
							    options=Options, timeout=Timeout}) ->
    case ssl:connect(Address, Port, Options, Timeout) of
        {ok, SslSocket} -> 
    	    {reply, {ok, {ok, SslSocket, From}}, #state{ssl_alive=[{SslSocket, From}|Alive], address=Address,
							port=Port, options=Options, timeout=Timeout}};
	SslError        ->
	    {reply, SslError, State}
    end;
handle_call(stop, _From, State) ->
    {stop, normal, ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast({push_apns, Packet, Resource}, State) ->
    {ok, SslSocket, _From} = Resource,
    ok = ssl:send(SslSocket, Packet),	    
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info({ssl, InSslSocket, Req}, State=#state{ssl_alive=Alive, address=_Address, port=_Port,
                                                            options=_Options, timeout=_Timeout}) ->
    From = proplists:get_value(InSslSocket, Alive),
    From ! Req,
    io:format("I(~p)[e-apns] apns incomming message ~p & sent to ~p\n", [self(), Req, From]),
    {noreply, State};
handle_info({ssl_closed, InSslSocket}, #state{ssl_alive=Alive, address=Address, port=Port,
                                                            options=Options, timeout=Timeout}) ->
    NewAlive = proplists:delete(InSslSocket, Alive),
    {noreply, #state{ssl_alive=NewAlive, address=Address, port=Port, options=Options, timeout=Timeout}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
