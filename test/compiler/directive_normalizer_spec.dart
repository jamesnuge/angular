library angular2.test.compiler.directive_normalizer_spec;

import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        beforeEach,
        ddescribe,
        describe,
        el,
        expect,
        iit,
        inject,
        it,
        xit,
        TestComponentBuilder,
        beforeEachProviders;
import "package:angular2/src/compiler/compile_metadata.dart"
    show CompileTypeMetadata, CompileTemplateMetadata;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/compiler/directive_normalizer.dart"
    show DirectiveNormalizer;
import "package:angular2/src/compiler/xhr.dart" show XHR;
import "package:angular2/src/compiler/xhr_mock.dart" show MockXHR;
import "test_bindings.dart" show TEST_PROVIDERS;

main() {
  describe("DirectiveNormalizer", () {
    CompileTypeMetadata dirType;
    beforeEachProviders(() => TEST_PROVIDERS);
    beforeEach(() {
      dirType = new CompileTypeMetadata(name: "SomeComp");
    });
    describe("loadTemplate", () {
      describe("inline template", () {
        it(
            "should store the template",
            inject([AsyncTestCompleter, DirectiveNormalizer],
                (async, DirectiveNormalizer normalizer) {
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: "a",
                          templateUrl: null,
                          styles: [],
                          styleUrls: ["test.css"],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.template).toEqual("a");
                expect(template.templateUrl)
                    .toEqual("package:some/module/a.js");
                async.done();
              });
            }));
        it(
            "should resolve styles on the annotation against the baseUrl",
            inject([AsyncTestCompleter, DirectiveNormalizer],
                (async, DirectiveNormalizer normalizer) {
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: "",
                          templateUrl: null,
                          styles: [],
                          styleUrls: ["test.css"],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.styleUrls)
                    .toEqual(["package:some/module/test.css"]);
                async.done();
              });
            }));
        it(
            "should resolve styles in the template against the baseUrl",
            inject([AsyncTestCompleter, DirectiveNormalizer],
                (async, DirectiveNormalizer normalizer) {
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: "<style>@import test.css</style>",
                          templateUrl: null,
                          styles: [],
                          styleUrls: [],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.styleUrls)
                    .toEqual(["package:some/module/test.css"]);
                async.done();
              });
            }));
      });
      describe("templateUrl", () {
        it(
            "should load a template from a url that is resolved against baseUrl",
            inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
                (async, DirectiveNormalizer normalizer, MockXHR xhr) {
              xhr.expect("package:some/module/sometplurl.html", "a");
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: null,
                          templateUrl: "sometplurl.html",
                          styles: [],
                          styleUrls: ["test.css"],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.template).toEqual("a");
                expect(template.templateUrl)
                    .toEqual("package:some/module/sometplurl.html");
                async.done();
              });
              xhr.flush();
            }));
        it(
            "should resolve styles on the annotation against the baseUrl",
            inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
                (async, DirectiveNormalizer normalizer, MockXHR xhr) {
              xhr.expect("package:some/module/tpl/sometplurl.html", "");
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: null,
                          templateUrl: "tpl/sometplurl.html",
                          styles: [],
                          styleUrls: ["test.css"],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.styleUrls)
                    .toEqual(["package:some/module/test.css"]);
                async.done();
              });
              xhr.flush();
            }));
        it(
            "should resolve styles in the template against the templateUrl",
            inject([AsyncTestCompleter, DirectiveNormalizer, XHR],
                (async, DirectiveNormalizer normalizer, MockXHR xhr) {
              xhr.expect("package:some/module/tpl/sometplurl.html",
                  "<style>@import test.css</style>");
              normalizer
                  .normalizeTemplate(
                      dirType,
                      new CompileTemplateMetadata(
                          encapsulation: null,
                          template: null,
                          templateUrl: "tpl/sometplurl.html",
                          styles: [],
                          styleUrls: [],
                          baseUrl: "package:some/module/a.js"))
                  .then((CompileTemplateMetadata template) {
                expect(template.styleUrls)
                    .toEqual(["package:some/module/tpl/test.css"]);
                async.done();
              });
              xhr.flush();
            }));
      });
      it(
          "should throw if no template was specified",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            expect(() => normalizer.normalizeTemplate(
                    dirType,
                    new CompileTemplateMetadata(
                        encapsulation: null, styles: [], styleUrls: [])))
                .toThrowError("No template specified for component SomeComp");
          }));
    });
    describe("normalizeLoadedTemplate", () {
      it(
          "should store the viewEncapsulationin the result",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var viewEncapsulation = ViewEncapsulation.Native;
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: viewEncapsulation,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "",
                "package:some/module/");
            expect(template.encapsulation).toBe(viewEncapsulation);
          }));
      it(
          "should keep the template as html",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "a",
                "package:some/module/");
            expect(template.template).toEqual("a");
          }));
      it(
          "should collect ngContent",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<ng-content select=\"a\"></ng-content>",
                "package:some/module/");
            expect(template.ngContentSelectors).toEqual(["a"]);
          }));
      it(
          "should normalize ngContent wildcard selector",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<ng-content></ng-content><ng-content select></ng-content><ng-content select=\"*\"></ng-content>",
                "package:some/module/");
            expect(template.ngContentSelectors).toEqual(["*", "*", "*"]);
          }));
      it(
          "should collect top level styles in the template",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<style>a</style>",
                "package:some/module/");
            expect(template.styles).toEqual(["a"]);
          }));
      it(
          "should collect styles inside in elements",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<div><style>a</style></div>",
                "package:some/module/");
            expect(template.styles).toEqual(["a"]);
          }));
      it(
          "should collect styleUrls in the template",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<link rel=\"stylesheet\" href=\"aUrl\">",
                "package:some/module/");
            expect(template.styleUrls).toEqual(["package:some/module/aUrl"]);
          }));
      it(
          "should collect styleUrls in elements",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<div><link rel=\"stylesheet\" href=\"aUrl\"></div>",
                "package:some/module/");
            expect(template.styleUrls).toEqual(["package:some/module/aUrl"]);
          }));
      it(
          "should ignore link elements with non stylesheet rel attribute",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<link href=\"b\" rel=\"a\">",
                "package:some/module/");
            expect(template.styleUrls).toEqual([]);
          }));
      it(
          "should ignore link elements with absolute urls but non package: scheme",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<link href=\"http://some/external.css\" rel=\"stylesheet\">",
                "package:some/module/");
            expect(template.styleUrls).toEqual([]);
          }));
      it(
          "should extract @import style urls into styleAbsUrl",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: ["@import \"test.css\";"],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "",
                "package:some/module/id");
            expect(template.styles).toEqual([""]);
            expect(template.styleUrls)
                .toEqual(["package:some/module/test.css"]);
          }));
      it(
          "should not resolve relative urls in inline styles",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [".foo{background-image: url('double.jpg');"],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "",
                "package:some/module/id");
            expect(template.styles)
                .toEqual([".foo{background-image: url('double.jpg');"]);
          }));
      it(
          "should resolve relative style urls in styleUrls",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: ["test.css"],
                    baseUrl: "package:some/module/a.js"),
                "",
                "package:some/module/id");
            expect(template.styles).toEqual([]);
            expect(template.styleUrls)
                .toEqual(["package:some/module/test.css"]);
          }));
      it(
          "should resolve relative style urls in styleUrls with http directive url",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: ["test.css"],
                    baseUrl: "http://some/module/a.js"),
                "",
                "http://some/module/id");
            expect(template.styles).toEqual([]);
            expect(template.styleUrls).toEqual(["http://some/module/test.css"]);
          }));
      it(
          "should normalize ViewEncapsulation.Emulated to ViewEncapsulation.None if there are no styles nor stylesheets",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: ViewEncapsulation.Emulated,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "",
                "package:some/module/id");
            expect(template.encapsulation).toEqual(ViewEncapsulation.None);
          }));
      it(
          "should ignore ng-content in elements with ngNonBindable",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<div ngNonBindable><ng-content select=\"a\"></ng-content></div>",
                "package:some/module/");
            expect(template.ngContentSelectors).toEqual([]);
          }));
      it(
          "should still collect <style> in elements with ngNonBindable",
          inject([DirectiveNormalizer], (DirectiveNormalizer normalizer) {
            var template = normalizer.normalizeLoadedTemplate(
                dirType,
                new CompileTemplateMetadata(
                    encapsulation: null,
                    styles: [],
                    styleUrls: [],
                    baseUrl: "package:some/module/a.js"),
                "<div ngNonBindable><style>div {color:red}</style></div>",
                "package:some/module/");
            expect(template.styles).toEqual(["div {color:red}"]);
          }));
    });
  });
}
