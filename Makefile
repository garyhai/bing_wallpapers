AGENT=com.ideasftw.bing-wallpaper
PLIST_FILE=~/Library/LaunchAgents/$(AGENT).plist
AGENT_FILE=Tools/$(AGENT).plist
ACTOR=bing-wallpaper.sh
ACTOR_FILE=/usr/local/bin/$(ACTOR)
LAUNCHER=launchctl

all:
	@echo "Please check your OS."
	@echo "Makefile support only MacOS."

install:
	@-$(LAUNCHER) unload $(PLIST_FILE) 2> /dev/null
	cp $(AGENT_FILE) $(PLIST_FILE)
	cp $(ACTOR) $(ACTOR_FILE)
	$(LAUNCHER) load $(PLIST_FILE)

uninstall:
	-$(LAUNCHER) unload $(PLIST_FILE)
	-rm -f $(PLIST_FILE)
	rm -f $(ACTOR_FILE)

test:
	$(LAUNCHER) start $(AGENT)

.PHONY: install uninstall all test
