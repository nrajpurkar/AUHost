default:
	@echo "Available actions:"
	@cat Makefile | grep ":$$" | sed 's/://' | xargs -I{} echo " - make {}"

ci:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.ci"

build:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.build"

clean:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.clean"

release:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.release"

verify:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.verify"

deploy:
	@ruby -r "`pwd`/Automation.rb" -e "Automation.deploy"
