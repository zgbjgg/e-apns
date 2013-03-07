# ==========================================================
#
# Makefile for e-apns erlang application
#
# Created by: Jorge Garrido <jorge.garrido@morelosoft.com>.
#
# ==========================================================

all: e-apns

e-apns: 
	@erl -make

clean:
	@rm -rf ebin/*.beam

demo:
	@erl -pa ebin/ -eval 'application:start('\''e-apns'\'')'
