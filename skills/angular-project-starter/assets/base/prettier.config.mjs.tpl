// Mirrors the Angular CLI defaults (width 100, single quotes, Angular HTML parser) and adds Tailwind class sorting.
// Class order is owned by prettier-plugin-tailwindcss; the ESLint plugin deliberately does not enforce order.
export default {
  printWidth: 100,
  singleQuote: true,
  plugins: ['prettier-plugin-tailwindcss'],
  tailwindStylesheet: './{{webSrc}}/styles.css',
  overrides: [{ files: '*.html', options: { parser: 'angular' } }],
};
