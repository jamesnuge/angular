library angular2.test.core.linker.projection_integration_spec;

import "package:angular2/testing_internal.dart"
    show
        AsyncTestCompleter,
        beforeEach,
        ddescribe,
        xdescribe,
        describe,
        el,
        dispatchEvent,
        expect,
        iit,
        inject,
        beforeEachProviders,
        it,
        xit,
        containsRegexp,
        stringifyElement,
        TestComponentBuilder,
        ComponentFixture,
        fakeAsync,
        tick;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/core.dart"
    show
        bind,
        provide,
        Component,
        Directive,
        ElementRef,
        TemplateRef,
        ViewContainerRef,
        ViewEncapsulation,
        ViewMetadata;
import "package:angular2/platform/common_dom.dart" show By;
import "package:angular2/src/core/debug/debug_node.dart" show getAllDebugNodes;

main() {
  describe("projection", () {
    it(
        "should support simple components",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple>" + "<div>A</div>" + "</simple>",
                      directives: [Simple]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement).toHaveText("SIMPLE(A)");
            async.done();
          });
        }));
    it(
        "should support simple components with text interpolation as direct children",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "{{'START('}}<simple>" +
                          "{{text}}" +
                          "</simple>{{')END'}}",
                      directives: [Simple]))
              .createAsync(MainComp)
              .then((main) {
            main.debugElement.componentInstance.text = "A";
            main.detectChanges();
            expect(main.debugElement.nativeElement)
                .toHaveText("START(SIMPLE(A))END");
            async.done();
          });
        }));
    it(
        "should support projecting text interpolation to a non bound element",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  Simple,
                  new ViewMetadata(
                      template: "SIMPLE(<div><ng-content></ng-content></div>)",
                      directives: []))
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple>{{text}}</simple>",
                      directives: [Simple]))
              .createAsync(MainComp)
              .then((main) {
            main.debugElement.componentInstance.text = "A";
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("SIMPLE(A)");
            async.done();
          });
        }));
    it(
        "should support projecting text interpolation to a non bound element with other bound elements after it",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  Simple,
                  new ViewMetadata(
                      template:
                          "SIMPLE(<div><ng-content></ng-content></div><div [tabIndex]=\"0\">EL</div>)",
                      directives: []))
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple>{{text}}</simple>",
                      directives: [Simple]))
              .createAsync(MainComp)
              .then((main) {
            main.debugElement.componentInstance.text = "A";
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("SIMPLE(AEL)");
            async.done();
          });
        }));
    it(
        "should project content components",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  Simple,
                  new ViewMetadata(
                      template: "SIMPLE({{0}}|<ng-content></ng-content>|{{2}})",
                      directives: []))
              .overrideView(OtherComp,
                  new ViewMetadata(template: "{{1}}", directives: []))
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple><other></other></simple>",
                      directives: [Simple, OtherComp]))
              .createAsync(MainComp)
              .then((main) {
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("SIMPLE(0|1|2)");
            async.done();
          });
        }));
    it(
        "should not show the light dom even if there is no content tag",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<empty>A</empty>", directives: [Empty]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement).toHaveText("");
            async.done();
          });
        }));
    it(
        "should support multiple content tags",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<multiple-content-tags>" +
                          "<div>B</div>" +
                          "<div>C</div>" +
                          "<div class=\"left\">A</div>" +
                          "</multiple-content-tags>",
                      directives: [MultipleContentTagsComponent]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement).toHaveText("(A, BC)");
            async.done();
          });
        }));
    it(
        "should redistribute only direct children",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<multiple-content-tags>" +
                          "<div>B<div class=\"left\">A</div></div>" +
                          "<div>C</div>" +
                          "</multiple-content-tags>",
                      directives: [MultipleContentTagsComponent]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement).toHaveText("(, BAC)");
            async.done();
          });
        }));
    it(
        "should redistribute direct child viewcontainers when the light dom changes",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<multiple-content-tags>" +
                          "<template manual class=\"left\"><div>A1</div></template>" +
                          "<div>B</div>" +
                          "</multiple-content-tags>",
                      directives: [
                        MultipleContentTagsComponent,
                        ManualViewportDirective
                      ]))
              .createAsync(MainComp)
              .then((main) {
            var viewportDirectives = main.debugElement.children[0].childNodes
                .where(By.directive(ManualViewportDirective))
                .toList()
                .map((de) => de.inject(ManualViewportDirective))
                .toList();
            expect(main.debugElement.nativeElement).toHaveText("(, B)");
            viewportDirectives.forEach((d) => d.show());
            expect(main.debugElement.nativeElement).toHaveText("(A1, B)");
            viewportDirectives.forEach((d) => d.hide());
            expect(main.debugElement.nativeElement).toHaveText("(, B)");
            async.done();
          });
        }));
    it(
        "should support nested components",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<outer-with-indirect-nested>" +
                          "<div>A</div>" +
                          "<div>B</div>" +
                          "</outer-with-indirect-nested>",
                      directives: [OuterWithIndirectNestedComponent]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement)
                .toHaveText("OUTER(SIMPLE(AB))");
            async.done();
          });
        }));
    it(
        "should support nesting with content being direct child of a nested component",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<outer>" +
                          "<template manual class=\"left\"><div>A</div></template>" +
                          "<div>B</div>" +
                          "<div>C</div>" +
                          "</outer>",
                      directives: [OuterComponent, ManualViewportDirective]))
              .createAsync(MainComp)
              .then((main) {
            var viewportDirective = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            expect(main.debugElement.nativeElement)
                .toHaveText("OUTER(INNER(INNERINNER(,BC)))");
            viewportDirective.show();
            expect(main.debugElement.nativeElement)
                .toHaveText("OUTER(INNER(INNERINNER(A,BC)))");
            async.done();
          });
        }));
    it(
        "should redistribute when the shadow dom changes",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<conditional-content>" +
                          "<div class=\"left\">A</div>" +
                          "<div>B</div>" +
                          "<div>C</div>" +
                          "</conditional-content>",
                      directives: [ConditionalContentComponent]))
              .createAsync(MainComp)
              .then((main) {
            var viewportDirective = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            expect(main.debugElement.nativeElement).toHaveText("(, BC)");
            viewportDirective.show();
            expect(main.debugElement.nativeElement).toHaveText("(A, BC)");
            viewportDirective.hide();
            expect(main.debugElement.nativeElement).toHaveText("(, BC)");
            async.done();
          });
        }));
    // GH-2095 - https://github.com/angular/angular/issues/2095

    // important as we are removing the ng-content element during compilation,

    // which could skrew up text node indices.
    it(
        "should support text nodes after content tags",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple stringProp=\"text\"></simple>",
                      directives: [Simple]))
              .overrideTemplate(
                  Simple, "<ng-content></ng-content><p>P,</p>{{stringProp}}")
              .createAsync(MainComp)
              .then((ComponentFixture main) {
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("P,text");
            async.done();
          });
        }));
    // important as we are moving style tags around during compilation,

    // which could skrew up text node indices.
    it(
        "should support text nodes after style tags",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<simple stringProp=\"text\"></simple>",
                      directives: [Simple]))
              .overrideTemplate(
                  Simple, "<style></style><p>P,</p>{{stringProp}}")
              .createAsync(MainComp)
              .then((ComponentFixture main) {
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("P,text");
            async.done();
          });
        }));
    it(
        "should support moving non projected light dom around",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<empty>" +
                          "  <template manual><div>A</div></template>" +
                          "</empty>" +
                          "START(<div project></div>)END",
                      directives: [
                        Empty,
                        ProjectDirective,
                        ManualViewportDirective
                      ]))
              .createAsync(MainComp)
              .then((main) {
            var sourceDirective;
            // We can't use the child nodes to get a hold of this because it's not in the dom at

            // all.
            getAllDebugNodes().forEach((debug) {
              if (!identical(
                  debug.providerTokens.indexOf(ManualViewportDirective), -1)) {
                sourceDirective = debug.inject(ManualViewportDirective);
              }
            });
            ProjectDirective projectDirective = main.debugElement
                .queryAllNodes(By.directive(ProjectDirective))[0]
                .inject(ProjectDirective);
            expect(main.debugElement.nativeElement).toHaveText("START()END");
            projectDirective.show(sourceDirective.templateRef);
            expect(main.debugElement.nativeElement).toHaveText("START(A)END");
            async.done();
          });
        }));
    it(
        "should support moving projected light dom around",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template:
                          "<simple><template manual><div>A</div></template></simple>" +
                              "START(<div project></div>)END",
                      directives: [
                        Simple,
                        ProjectDirective,
                        ManualViewportDirective
                      ]))
              .createAsync(MainComp)
              .then((main) {
            ManualViewportDirective sourceDirective = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            ProjectDirective projectDirective = main.debugElement
                .queryAllNodes(By.directive(ProjectDirective))[0]
                .inject(ProjectDirective);
            expect(main.debugElement.nativeElement)
                .toHaveText("SIMPLE()START()END");
            projectDirective.show(sourceDirective.templateRef);
            expect(main.debugElement.nativeElement)
                .toHaveText("SIMPLE()START(A)END");
            async.done();
          });
        }));
    it(
        "should support moving ng-content around",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<conditional-content>" +
                          "<div class=\"left\">A</div>" +
                          "<div>B</div>" +
                          "</conditional-content>" +
                          "START(<div project></div>)END",
                      directives: [
                        ConditionalContentComponent,
                        ProjectDirective,
                        ManualViewportDirective
                      ]))
              .createAsync(MainComp)
              .then((main) {
            ManualViewportDirective sourceDirective = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            ProjectDirective projectDirective = main.debugElement
                .queryAllNodes(By.directive(ProjectDirective))[0]
                .inject(ProjectDirective);
            expect(main.debugElement.nativeElement)
                .toHaveText("(, B)START()END");
            projectDirective.show(sourceDirective.templateRef);
            expect(main.debugElement.nativeElement)
                .toHaveText("(, B)START(A)END");
            // Stamping ng-content multiple times should not produce the content multiple

            // times...
            projectDirective.show(sourceDirective.templateRef);
            expect(main.debugElement.nativeElement)
                .toHaveText("(, B)START(A)END");
            async.done();
          });
        }));
    // Note: This does not use a ng-content element, but

    // is still important as we are merging proto views independent of

    // the presence of ng-content elements!
    it(
        "should still allow to implement a recursive trees",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<tree></tree>", directives: [Tree]))
              .createAsync(MainComp)
              .then((main) {
            main.detectChanges();
            ManualViewportDirective manualDirective = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            expect(main.debugElement.nativeElement).toHaveText("TREE(0:)");
            manualDirective.show();
            main.detectChanges();
            expect(main.debugElement.nativeElement)
                .toHaveText("TREE(0:TREE(1:))");
            async.done();
          });
        }));
    // Note: This does not use a ng-content element, but

    // is still important as we are merging proto views independent of

    // the presence of ng-content elements!
    it(
        "should still allow to implement a recursive trees via multiple components",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<tree></tree>", directives: [Tree]))
              .overrideView(
                  Tree,
                  new ViewMetadata(
                      template:
                          "TREE({{depth}}:<tree2 *manual [depth]=\"depth+1\"></tree2>)",
                      directives: [Tree2, ManualViewportDirective]))
              .createAsync(MainComp)
              .then((main) {
            main.detectChanges();
            expect(main.debugElement.nativeElement).toHaveText("TREE(0:)");
            var tree = main.debugElement.query(By.directive(Tree));
            ManualViewportDirective manualDirective = tree
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            manualDirective.show();
            main.detectChanges();
            expect(main.debugElement.nativeElement)
                .toHaveText("TREE(0:TREE2(1:))");
            var tree2 = main.debugElement.query(By.directive(Tree2));
            manualDirective = tree2
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            manualDirective.show();
            main.detectChanges();
            expect(main.debugElement.nativeElement)
                .toHaveText("TREE(0:TREE2(1:TREE(2:)))");
            async.done();
          });
        }));
    if (DOM.supportsNativeShadowDOM()) {
      it(
          "should support native content projection and isolate styles per component",
          inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MainComp,
                    new ViewMetadata(
                        template:
                            "<simple-native1><div>A</div></simple-native1>" +
                                "<simple-native2><div>B</div></simple-native2>",
                        directives: [SimpleNative1, SimpleNative2]))
                .createAsync(MainComp)
                .then((main) {
              var childNodes = DOM.childNodes(main.debugElement.nativeElement);
              expect(childNodes[0]).toHaveText("div {color: red}SIMPLE1(A)");
              expect(childNodes[1]).toHaveText("div {color: blue}SIMPLE2(B)");
              main.destroy();
              async.done();
            });
          }));
    }
    if (DOM.supportsDOMEvents()) {
      it(
          "should support non emulated styles",
          inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MainComp,
                    new ViewMetadata(
                        template: "<div class=\"redStyle\"></div>",
                        styles: [".redStyle { color: red}"],
                        encapsulation: ViewEncapsulation.None,
                        directives: [OtherComp]))
                .createAsync(MainComp)
                .then((main) {
              var mainEl = main.debugElement.nativeElement;
              var div1 = DOM.firstChild(mainEl);
              var div2 = DOM.createElement("div");
              DOM.setAttribute(div2, "class", "redStyle");
              DOM.appendChild(mainEl, div2);
              expect(DOM.getComputedStyle(div1).color)
                  .toEqual("rgb(255, 0, 0)");
              expect(DOM.getComputedStyle(div2).color)
                  .toEqual("rgb(255, 0, 0)");
              async.done();
            });
          }));
      it(
          "should support emulated style encapsulation",
          inject([TestComponentBuilder, AsyncTestCompleter],
              (TestComponentBuilder tcb, async) {
            tcb
                .overrideView(
                    MainComp,
                    new ViewMetadata(
                        template: "<div></div>",
                        styles: ["div { color: red}"],
                        encapsulation: ViewEncapsulation.Emulated))
                .createAsync(MainComp)
                .then((main) {
              var mainEl = main.debugElement.nativeElement;
              var div1 = DOM.firstChild(mainEl);
              var div2 = DOM.createElement("div");
              DOM.appendChild(mainEl, div2);
              expect(DOM.getComputedStyle(div1).color)
                  .toEqual("rgb(255, 0, 0)");
              expect(DOM.getComputedStyle(div2).color).toEqual("rgb(0, 0, 0)");
              async.done();
            });
          }));
    }
    it(
        "should support nested conditionals that contain ng-contents",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: '''<conditional-text>a</conditional-text>''',
                      directives: [ConditionalTextComponent]))
              .createAsync(MainComp)
              .then((main) {
            expect(main.debugElement.nativeElement).toHaveText("MAIN()");
            var viewportElement = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[0];
            viewportElement.inject(ManualViewportDirective).show();
            expect(main.debugElement.nativeElement).toHaveText("MAIN(FIRST())");
            viewportElement = main.debugElement
                .queryAllNodes(By.directive(ManualViewportDirective))[1];
            viewportElement.inject(ManualViewportDirective).show();
            expect(main.debugElement.nativeElement)
                .toHaveText("MAIN(FIRST(SECOND(a)))");
            async.done();
          });
        }));
    it(
        "should allow to switch the order of nested components via ng-content",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: '''<cmp-a><cmp-b></cmp-b></cmp-a>''',
                      directives: [CmpA, CmpB]))
              .createAsync(MainComp)
              .then((main) {
            main.detectChanges();
            expect(DOM.getInnerHTML(main.debugElement.nativeElement)).toEqual(
                "<cmp-a><cmp-b><cmp-d><d>cmp-d</d></cmp-d></cmp-b>" +
                    "<cmp-c><c>cmp-c</c></cmp-c></cmp-a>");
            async.done();
          });
        }));
    it(
        "should create nested components in the right order",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: '''<cmp-a1></cmp-a1><cmp-a2></cmp-a2>''',
                      directives: [CmpA1, CmpA2]))
              .createAsync(MainComp)
              .then((main) {
            main.detectChanges();
            expect(DOM.getInnerHTML(main.debugElement.nativeElement)).toEqual(
                "<cmp-a1>a1<cmp-b11>b11</cmp-b11><cmp-b12>b12</cmp-b12></cmp-a1>" +
                    "<cmp-a2>a2<cmp-b21>b21</cmp-b21><cmp-b22>b22</cmp-b22></cmp-a2>");
            async.done();
          });
        }));
    it(
        "should project filled view containers into a view container",
        inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, async) {
          tcb
              .overrideView(
                  MainComp,
                  new ViewMetadata(
                      template: "<conditional-content>" +
                          "<div class=\"left\">A</div>" +
                          "<template manual class=\"left\">B</template>" +
                          "<div class=\"left\">C</div>" +
                          "<div>D</div>" +
                          "</conditional-content>",
                      directives: [
                        ConditionalContentComponent,
                        ManualViewportDirective
                      ]))
              .createAsync(MainComp)
              .then((main) {
            var conditionalComp = main.debugElement
                .query(By.directive(ConditionalContentComponent));
            var viewViewportDir = conditionalComp
                .queryAllNodes(By.directive(ManualViewportDirective))[0]
                .inject(ManualViewportDirective);
            expect(main.debugElement.nativeElement).toHaveText("(, D)");
            expect(main.debugElement.nativeElement).toHaveText("(, D)");
            viewViewportDir.show();
            expect(main.debugElement.nativeElement).toHaveText("(AC, D)");
            var contentViewportDir = conditionalComp
                .queryAllNodes(By.directive(ManualViewportDirective))[1]
                .inject(ManualViewportDirective);
            contentViewportDir.show();
            expect(main.debugElement.nativeElement).toHaveText("(ABC, D)");
            // hide view viewport, and test that it also hides

            // the content viewport's views
            viewViewportDir.hide();
            expect(main.debugElement.nativeElement).toHaveText("(, D)");
            async.done();
          });
        }));
  });
}

@Component(selector: "main", template: "", directives: const [])
class MainComp {
  String text = "";
}

@Component(selector: "other", template: "", directives: const [])
class OtherComp {
  String text = "";
}

@Component(
    selector: "simple",
    inputs: const ["stringProp"],
    template: "SIMPLE(<ng-content></ng-content>)",
    directives: const [])
class Simple {
  String stringProp = "";
}

@Component(
    selector: "simple-native1",
    template: "SIMPLE1(<content></content>)",
    directives: const [],
    encapsulation: ViewEncapsulation.Native,
    styles: const ["div {color: red}"])
class SimpleNative1 {}

@Component(
    selector: "simple-native2",
    template: "SIMPLE2(<content></content>)",
    directives: const [],
    encapsulation: ViewEncapsulation.Native,
    styles: const ["div {color: blue}"])
class SimpleNative2 {}

@Component(selector: "empty", template: "", directives: const [])
class Empty {}

@Component(
    selector: "multiple-content-tags",
    template:
        "(<ng-content SELECT=\".left\"></ng-content>, <ng-content></ng-content>)",
    directives: const [])
class MultipleContentTagsComponent {}

@Directive(selector: "[manual]")
class ManualViewportDirective {
  ViewContainerRef vc;
  TemplateRef<Object> templateRef;
  ManualViewportDirective(this.vc, this.templateRef) {}
  show() {
    this.vc.createEmbeddedView(this.templateRef);
  }

  hide() {
    this.vc.clear();
  }
}

@Directive(selector: "[project]")
class ProjectDirective {
  ViewContainerRef vc;
  ProjectDirective(this.vc) {}
  show(TemplateRef<Object> templateRef) {
    this.vc.createEmbeddedView(templateRef);
  }

  hide() {
    this.vc.clear();
  }
}

@Component(
    selector: "outer-with-indirect-nested",
    template: "OUTER(<simple><div><ng-content></ng-content></div></simple>)",
    directives: const [Simple])
class OuterWithIndirectNestedComponent {}

@Component(
    selector: "outer",
    template:
        "OUTER(<inner><ng-content select=\".left\" class=\"left\"></ng-content><ng-content></ng-content></inner>)",
    directives: const [InnerComponent])
class OuterComponent {}

@Component(
    selector: "inner",
    template:
        "INNER(<innerinner><ng-content select=\".left\" class=\"left\"></ng-content><ng-content></ng-content></innerinner>)",
    directives: const [InnerInnerComponent])
class InnerComponent {}

@Component(
    selector: "innerinner",
    template:
        "INNERINNER(<ng-content select=\".left\"></ng-content>,<ng-content></ng-content>)",
    directives: const [])
class InnerInnerComponent {}

@Component(
    selector: "conditional-content",
    template:
        "<div>(<div *manual><ng-content select=\".left\"></ng-content></div>, <ng-content></ng-content>)</div>",
    directives: const [ManualViewportDirective])
class ConditionalContentComponent {}

@Component(
    selector: "conditional-text",
    template:
        "MAIN(<template manual>FIRST(<template manual>SECOND(<ng-content></ng-content>)</template>)</template>)",
    directives: const [ManualViewportDirective])
class ConditionalTextComponent {}

@Component(
    selector: "tab",
    template: "<div><div *manual>TAB(<ng-content></ng-content>)</div></div>",
    directives: const [ManualViewportDirective])
class Tab {}

@Component(
    selector: "tree2",
    inputs: const ["depth"],
    template: "TREE2({{depth}}:<tree *manual [depth]=\"depth+1\"></tree>)",
    directives: const [ManualViewportDirective, Tree])
class Tree2 {
  var depth = 0;
}

@Component(
    selector: "tree",
    inputs: const ["depth"],
    template: "TREE({{depth}}:<tree *manual [depth]=\"depth+1\"></tree>)",
    directives: const [ManualViewportDirective, Tree, Tree])
class Tree {
  var depth = 0;
}

@Component(selector: "cmp-d", template: '''<d>{{tagName}}</d>''')
class CmpD {
  String tagName;
  CmpD(ElementRef elementRef) {
    this.tagName = DOM.tagName(elementRef.nativeElement).toLowerCase();
  }
}

@Component(selector: "cmp-c", template: '''<c>{{tagName}}</c>''')
class CmpC {
  String tagName;
  CmpC(ElementRef elementRef) {
    this.tagName = DOM.tagName(elementRef.nativeElement).toLowerCase();
  }
}

@Component(
    selector: "cmp-b",
    template: '''<ng-content></ng-content><cmp-d></cmp-d>''',
    directives: const [CmpD])
class CmpB {}

@Component(
    selector: "cmp-a",
    template: '''<ng-content></ng-content><cmp-c></cmp-c>''',
    directives: const [CmpC])
class CmpA {}

@Component(
    selector: "cmp-b11", template: '''{{\'b11\'}}''', directives: const [])
class CmpB11 {}

@Component(
    selector: "cmp-b12", template: '''{{\'b12\'}}''', directives: const [])
class CmpB12 {}

@Component(
    selector: "cmp-b21", template: '''{{\'b21\'}}''', directives: const [])
class CmpB21 {}

@Component(
    selector: "cmp-b22", template: '''{{\'b22\'}}''', directives: const [])
class CmpB22 {}

@Component(
    selector: "cmp-a1",
    template: '''{{\'a1\'}}<cmp-b11></cmp-b11><cmp-b12></cmp-b12>''',
    directives: const [CmpB11, CmpB12])
class CmpA1 {}

@Component(
    selector: "cmp-a2",
    template: '''{{\'a2\'}}<cmp-b21></cmp-b21><cmp-b22></cmp-b22>''',
    directives: const [CmpB21, CmpB22])
class CmpA2 {}
