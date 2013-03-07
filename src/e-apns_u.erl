%% ==============================================================================
%
% This module implements utilities for apns, create a correct payload, encodes a
% token for the device id & make a valid packet for apns.
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

-module('e-apns_u').

-export([payload/3, hex_token/1, packet/4]).

%% @doc creates a payload json format, we need alert, sound and badge.
%% @spec payload(Alert::string(), Sound::string(), Badge::string()) -> binary().
-spec payload(Alert::string(), Sound::string(), Badge::string()) -> binary().
payload(Alert, Sound, Badge) ->
    Json = "{\"aps\":{\"alert\":\""++Alert++"\",\"sound\":\""++Sound++"\", \"badge\":"++Badge++"}}",
    list_to_binary(Json).

%% @doc encodes token as hexadecimal data.
%% @spec hex_token(Token::string()) -> integer().
-spec hex_token(Token::string()) -> integer().
hex_token(Token) ->
   list_to_integer(Token, 16).

%% @doc creates a valid packet for apns 
%% @spec packet(Identifier::integer(), Expiry::integer(), HexToken::integer(), Payload::binary()) -> binary().
-spec packet(Identifier::integer(), Expiry::integer(), HexToken::integer(), Payload::binary()) -> binary().
packet(Identifier, Expiry, HexToken, Payload) ->
    PayloadLength = erlang:size(Payload),
    <<1:8, Identifier:32, Expiry:32, 32:16/big, HexToken:256/big, PayloadLength:16/big, Payload/binary>>. 
