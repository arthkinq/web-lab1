import scss from 'rollup-plugin-scss';
import coffeescript from 'rollup-plugin-coffee-script';

export default {
        input: 'src/index.coffee',
    output: {
        file: 'dist/bundle.js',
        format: 'iife',
    },
    plugins: [
        scss({
            output: 'dist/styles.css',
            outputStyle: 'compressed',
            fileName: 'styles.css',
            sourceMap: false,
            failOnError: true,
        }),
        coffeescript()
    ]
};