library angular2.src.compiler.metadata_resolver;

import "package:angular2/src/core/di.dart" show resolveForwardRef;
import "package:angular2/src/facade/lang.dart"
    show
        Type,
        isBlank,
        isPresent,
        isArray,
        stringify,
        isString,
        isStringMap,
        RegExpWrapper,
        StringWrapper;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "compile_metadata.dart" as cpl;
import "package:angular2/src/core/metadata/directives.dart" as md;
import "package:angular2/src/core/metadata/di.dart" as dimd;
import "directive_resolver.dart" show DirectiveResolver;
import "pipe_resolver.dart" show PipeResolver;
import "view_resolver.dart" show ViewResolver;
import "package:angular2/src/core/metadata/view.dart" show ViewMetadata;
import "directive_lifecycle_reflector.dart" show hasLifecycleHook;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart"
    show LifecycleHooks, LIFECYCLE_HOOKS_VALUES;
import "package:angular2/src/core/reflection/reflection.dart" show reflector;
import "package:angular2/src/core/di.dart" show Injectable, Inject, Optional;
import "package:angular2/src/core/platform_directives_and_pipes.dart"
    show PLATFORM_DIRECTIVES, PLATFORM_PIPES;
import "util.dart" show MODULE_SUFFIX, sanitizeIdentifier;
import "assertions.dart" show assertArrayOfStrings;
import "package:angular2/src/compiler/url_resolver.dart" show getUrlScheme;
import "package:angular2/src/core/di/provider.dart" show Provider;
import "package:angular2/src/core/di/metadata.dart"
    show
        OptionalMetadata,
        SelfMetadata,
        HostMetadata,
        SkipSelfMetadata,
        InjectMetadata;
import "package:angular2/src/core/metadata/di.dart"
    show AttributeMetadata, QueryMetadata;
import "package:angular2/src/core/reflection/reflector_reader.dart"
    show ReflectorReader;

@Injectable()
class CompileMetadataResolver {
  DirectiveResolver _directiveResolver;
  PipeResolver _pipeResolver;
  ViewResolver _viewResolver;
  List<Type> _platformDirectives;
  List<Type> _platformPipes;
  var _directiveCache = new Map<Type, cpl.CompileDirectiveMetadata>();
  var _pipeCache = new Map<Type, cpl.CompilePipeMetadata>();
  var _anonymousTypes = new Map<Object, num>();
  var _anonymousTypeIndex = 0;
  ReflectorReader _reflector;
  CompileMetadataResolver(
      this._directiveResolver,
      this._pipeResolver,
      this._viewResolver,
      @Optional() @Inject(PLATFORM_DIRECTIVES) this._platformDirectives,
      @Optional() @Inject(PLATFORM_PIPES) this._platformPipes,
      [ReflectorReader _reflector]) {
    if (isPresent(_reflector)) {
      this._reflector = _reflector;
    } else {
      this._reflector = reflector;
    }
  }
  String sanitizeTokenName(dynamic token) {
    var identifier = stringify(token);
    if (identifier.indexOf("(") >= 0) {
      // case: anonymous functions!
      var found = this._anonymousTypes[token];
      if (isBlank(found)) {
        this._anonymousTypes[token] = this._anonymousTypeIndex++;
        found = this._anonymousTypes[token];
      }
      identifier = '''anonymous_token_${ found}_''';
    }
    return sanitizeIdentifier(identifier);
  }

  cpl.CompileDirectiveMetadata getDirectiveMetadata(Type directiveType) {
    var meta = this._directiveCache[directiveType];
    if (isBlank(meta)) {
      var dirMeta = this._directiveResolver.resolve(directiveType);
      var templateMeta = null;
      var changeDetectionStrategy = null;
      var viewProviders = [];
      if (dirMeta is md.ComponentMetadata) {
        assertArrayOfStrings("styles", dirMeta.styles);
        var cmpMeta = (dirMeta as md.ComponentMetadata);
        var viewMeta = this._viewResolver.resolve(directiveType);
        assertArrayOfStrings("styles", viewMeta.styles);
        templateMeta = new cpl.CompileTemplateMetadata(
            encapsulation: viewMeta.encapsulation,
            template: viewMeta.template,
            templateUrl: viewMeta.templateUrl,
            styles: viewMeta.styles,
            styleUrls: viewMeta.styleUrls,
            baseUrl:
                calcTemplateBaseUrl(this._reflector, directiveType, cmpMeta));
        changeDetectionStrategy = cmpMeta.changeDetection;
        if (isPresent(dirMeta.viewProviders)) {
          viewProviders = this.getProvidersMetadata(dirMeta.viewProviders);
        }
      }
      var providers = [];
      if (isPresent(dirMeta.providers)) {
        providers = this.getProvidersMetadata(dirMeta.providers);
      }
      var queries = [];
      var viewQueries = [];
      if (isPresent(dirMeta.queries)) {
        queries = this.getQueriesMetadata(dirMeta.queries, false);
        viewQueries = this.getQueriesMetadata(dirMeta.queries, true);
      }
      meta = cpl.CompileDirectiveMetadata.create(
          selector: dirMeta.selector,
          exportAs: dirMeta.exportAs,
          isComponent: isPresent(templateMeta),
          type: this.getTypeMetadata(
              directiveType, staticTypeModuleUrl(directiveType)),
          template: templateMeta,
          changeDetection: changeDetectionStrategy,
          inputs: dirMeta.inputs,
          outputs: dirMeta.outputs,
          host: dirMeta.host,
          lifecycleHooks: LIFECYCLE_HOOKS_VALUES
              .where((hook) => hasLifecycleHook(hook, directiveType))
              .toList(),
          providers: providers,
          viewProviders: viewProviders,
          queries: queries,
          viewQueries: viewQueries);
      this._directiveCache[directiveType] = meta;
    }
    return meta;
  }

  /**
   * 
   * 
   */
  cpl.CompileDirectiveMetadata maybeGetDirectiveMetadata(Type someType) {
    try {
      return this.getDirectiveMetadata(someType);
    } catch (e, e_stack) {
      if (!identical(e.message.indexOf("No Directive annotation"), -1)) {
        return null;
      }
      rethrow;
    }
  }

  cpl.CompileTypeMetadata getTypeMetadata(Type type, String moduleUrl) {
    return new cpl.CompileTypeMetadata(
        name: this.sanitizeTokenName(type),
        moduleUrl: moduleUrl,
        runtime: type,
        diDeps: this.getDependenciesMetadata(type, null));
  }

  cpl.CompileFactoryMetadata getFactoryMetadata(
      Function factory, String moduleUrl) {
    return new cpl.CompileFactoryMetadata(
        name: this.sanitizeTokenName(factory),
        moduleUrl: moduleUrl,
        runtime: factory,
        diDeps: this.getDependenciesMetadata(factory, null));
  }

  cpl.CompilePipeMetadata getPipeMetadata(Type pipeType) {
    var meta = this._pipeCache[pipeType];
    if (isBlank(meta)) {
      var pipeMeta = this._pipeResolver.resolve(pipeType);
      meta = new cpl.CompilePipeMetadata(
          type: this.getTypeMetadata(pipeType, staticTypeModuleUrl(pipeType)),
          name: pipeMeta.name,
          pure: pipeMeta.pure,
          lifecycleHooks: LIFECYCLE_HOOKS_VALUES
              .where((hook) => hasLifecycleHook(hook, pipeType))
              .toList());
      this._pipeCache[pipeType] = meta;
    }
    return meta;
  }

  List<cpl.CompileDirectiveMetadata> getViewDirectivesMetadata(Type component) {
    var view = this._viewResolver.resolve(component);
    var directives = flattenDirectives(view, this._platformDirectives);
    for (var i = 0; i < directives.length; i++) {
      if (!isValidType(directives[i])) {
        throw new BaseException(
            '''Unexpected directive value \'${ stringify ( directives [ i ] )}\' on the View of component \'${ stringify ( component )}\'''');
      }
    }
    return directives.map((type) => this.getDirectiveMetadata(type)).toList();
  }

  List<cpl.CompilePipeMetadata> getViewPipesMetadata(Type component) {
    var view = this._viewResolver.resolve(component);
    var pipes = flattenPipes(view, this._platformPipes);
    for (var i = 0; i < pipes.length; i++) {
      if (!isValidType(pipes[i])) {
        throw new BaseException(
            '''Unexpected piped value \'${ stringify ( pipes [ i ] )}\' on the View of component \'${ stringify ( component )}\'''');
      }
    }
    return pipes.map((type) => this.getPipeMetadata(type)).toList();
  }

  List<cpl.CompileDiDependencyMetadata> getDependenciesMetadata(
      dynamic /* Type | Function */ typeOrFunc, List<dynamic> dependencies) {
    var params = isPresent(dependencies)
        ? dependencies
        : this._reflector.parameters(typeOrFunc);
    if (isBlank(params)) {
      params = [];
    }
    return params.map((param) {
      if (isBlank(param)) {
        return null;
      }
      var isAttribute = false;
      var isHost = false;
      var isSelf = false;
      var isSkipSelf = false;
      var isOptional = false;
      dimd.QueryMetadata query = null;
      dimd.ViewQueryMetadata viewQuery = null;
      var token = null;
      if (isArray(param)) {
        ((param as List<dynamic>)).forEach((paramEntry) {
          if (paramEntry is HostMetadata) {
            isHost = true;
          } else if (paramEntry is SelfMetadata) {
            isSelf = true;
          } else if (paramEntry is SkipSelfMetadata) {
            isSkipSelf = true;
          } else if (paramEntry is OptionalMetadata) {
            isOptional = true;
          } else if (paramEntry is AttributeMetadata) {
            isAttribute = true;
            token = paramEntry.attributeName;
          } else if (paramEntry is QueryMetadata) {
            if (paramEntry.isViewQuery) {
              viewQuery = paramEntry;
            } else {
              query = paramEntry;
            }
          } else if (paramEntry is InjectMetadata) {
            token = paramEntry.token;
          } else if (isValidType(paramEntry) && isBlank(token)) {
            token = paramEntry;
          }
        });
      } else {
        token = param;
      }
      if (isBlank(token)) {
        return null;
      }
      return new cpl.CompileDiDependencyMetadata(
          isAttribute: isAttribute,
          isHost: isHost,
          isSelf: isSelf,
          isSkipSelf: isSkipSelf,
          isOptional: isOptional,
          query: isPresent(query) ? this.getQueryMetadata(query, null) : null,
          viewQuery: isPresent(viewQuery)
              ? this.getQueryMetadata(viewQuery, null)
              : null,
          token: this.getTokenMetadata(token));
    }).toList();
  }

  cpl.CompileTokenMetadata getTokenMetadata(dynamic token) {
    token = resolveForwardRef(token);
    var compileToken;
    if (isString(token)) {
      compileToken = new cpl.CompileTokenMetadata(value: token);
    } else {
      compileToken = new cpl.CompileTokenMetadata(
          identifier: new cpl.CompileIdentifierMetadata(
              runtime: token,
              name: this.sanitizeTokenName(token),
              moduleUrl: staticTypeModuleUrl(token)));
    }
    return compileToken;
  }

  List<dynamic /* cpl . CompileProviderMetadata | cpl . CompileTypeMetadata | List < dynamic > */ >
      getProvidersMetadata(List<dynamic> providers) {
    return providers.map((provider) {
      provider = resolveForwardRef(provider);
      if (isArray(provider)) {
        return this.getProvidersMetadata(provider);
      } else if (provider is Provider) {
        return this.getProviderMetadata(provider);
      } else {
        return this.getTypeMetadata(provider, staticTypeModuleUrl(provider));
      }
    }).toList();
  }

  cpl.CompileProviderMetadata getProviderMetadata(Provider provider) {
    var compileDeps;
    if (isPresent(provider.useClass)) {
      compileDeps = this
          .getDependenciesMetadata(provider.useClass, provider.dependencies);
    } else if (isPresent(provider.useFactory)) {
      compileDeps = this
          .getDependenciesMetadata(provider.useFactory, provider.dependencies);
    }
    return new cpl.CompileProviderMetadata(
        token: this.getTokenMetadata(provider.token),
        useClass: isPresent(provider.useClass)
            ? this.getTypeMetadata(
                provider.useClass, staticTypeModuleUrl(provider.useClass))
            : null,
        useValue: isPresent(provider.useValue)
            ? new cpl.CompileIdentifierMetadata(runtime: provider.useValue)
            : null,
        useFactory: isPresent(provider.useFactory)
            ? this.getFactoryMetadata(
                provider.useFactory, staticTypeModuleUrl(provider.useFactory))
            : null,
        useExisting: isPresent(provider.useExisting)
            ? this.getTokenMetadata(provider.useExisting)
            : null,
        deps: compileDeps,
        multi: provider.multi);
  }

  List<cpl.CompileQueryMetadata> getQueriesMetadata(
      Map<String, dimd.QueryMetadata> queries, bool isViewQuery) {
    var compileQueries = [];
    StringMapWrapper.forEach(queries, (query, propertyName) {
      if (identical(query.isViewQuery, isViewQuery)) {
        compileQueries.add(this.getQueryMetadata(query, propertyName));
      }
    });
    return compileQueries;
  }

  cpl.CompileQueryMetadata getQueryMetadata(
      dimd.QueryMetadata q, String propertyName) {
    var selectors;
    if (q.isVarBindingQuery) {
      selectors = q.varBindings
          .map((varName) => this.getTokenMetadata(varName))
          .toList();
    } else {
      selectors = [this.getTokenMetadata(q.selector)];
    }
    return new cpl.CompileQueryMetadata(
        selectors: selectors,
        first: q.first,
        descendants: q.descendants,
        propertyName: propertyName,
        read: isPresent(q.read) ? this.getTokenMetadata(q.read) : null);
  }
}

List<Type> flattenDirectives(
    ViewMetadata view, List<dynamic> platformDirectives) {
  var directives = [];
  if (isPresent(platformDirectives)) {
    flattenArray(platformDirectives, directives);
  }
  if (isPresent(view.directives)) {
    flattenArray(view.directives, directives);
  }
  return directives;
}

List<Type> flattenPipes(ViewMetadata view, List<dynamic> platformPipes) {
  var pipes = [];
  if (isPresent(platformPipes)) {
    flattenArray(platformPipes, pipes);
  }
  if (isPresent(view.pipes)) {
    flattenArray(view.pipes, pipes);
  }
  return pipes;
}

void flattenArray(
    List<dynamic> tree, List<dynamic /* Type | List < dynamic > */ > out) {
  for (var i = 0; i < tree.length; i++) {
    var item = resolveForwardRef(tree[i]);
    if (isArray(item)) {
      flattenArray(item, out);
    } else {
      out.add(item);
    }
  }
}

bool isStaticType(dynamic value) {
  return isStringMap(value) &&
      isPresent(value["name"]) &&
      isPresent(value["moduleId"]);
}

bool isValidType(dynamic value) {
  return isStaticType(value) || (value is Type);
}

String staticTypeModuleUrl(dynamic value) {
  return isStaticType(value) ? value["moduleId"] : null;
}

String calcTemplateBaseUrl(
    ReflectorReader reflector, dynamic type, md.ComponentMetadata cmpMetadata) {
  if (isStaticType(type)) {
    return type["filePath"];
  }
  if (isPresent(cmpMetadata.moduleId)) {
    var moduleId = cmpMetadata.moduleId;
    var scheme = getUrlScheme(moduleId);
    return isPresent(scheme) && scheme.length > 0
        ? moduleId
        : '''package:${ moduleId}${ MODULE_SUFFIX}''';
  }
  return reflector.importUri(type);
}
