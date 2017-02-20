through = require 'through2'
Vinyl = require 'vinyl'
path = require 'path'
lodash = require 'lodash'

module.exports = (options) -> 
    lastest = false
    modules = new Object
    main = new Object

    options = options or {}
    options.exports = options.exports or 'main'
    options.outputs = options.outputs or 'main.js'

    formatDependencies = (dependencies) ->
        lodash.map(
                dependencies,
                (dependency) -> """modules['#{dependency}']"""
            ).toString()

    requireFactory = (module) ->
        """var #{options.exports} = (#{module.code}).apply(
            #{options.exports},
            [#{formatDependencies module.deps}]
        );
        """

    defineFactory = (name, module) ->
        """
            modules['#{name}'] = (#{module.code}).apply(
                modules['#{name}'],
                [#{formatDependencies module.deps}]
            );\n
        """

    unify = (transversed) ->
        transversed.reduce(
            (acumulated, current) -> acumulated.concat current unless current of acumulated,
            new Array()
        )

    transverse = (deps, modules) ->
        deps.reduce(
            (acumulated, current) -> acumulated.concat transverse(modules[current].deps, modules),
            new Array()
        ).concat deps

    require = (deps, fn) ->
        main.code = fn.toString()
        main.deps = deps
        
    define = (name, deps, fn) ->
        modules[name] =
            'code' : fn.toString()
            'deps' : deps
            'found' : false

    deamdfy = (file, enc, cb) ->
        eval file.contents.toString()
        lastest = file
        cb()

    formatModules = (acumulated, name) -> acumulated.concat defineFactory name, modules[name]

    return through objectMode: true, deamdfy, (cb) ->
        order = unify transverse main.deps, modules
        content = order
            .reduce formatModules, 'var modules = {};\n'
            .concat requireFactory main
        built = lastest.clone()
        built.contents = new Buffer(content)
        built.path = path.join(lastest.base, options.outputs)
        this.push built
        cb()