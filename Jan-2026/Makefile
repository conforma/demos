
build: \
  build-01-validate-input-basics

BLOG_HOME=../../conforma.github.io/website/content/posts

build-%:
	MARKDOWN_MODE=1 TRANSCRIPT_MODE=1 ./$*.sh &> $(BLOG_HOME)/$*.md

clean:
	rm -rf ./tmp-work-*
