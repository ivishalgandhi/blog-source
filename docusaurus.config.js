// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'The Data Column',
  tagline: 'FOSS.NoSQL.Databases.Containers - Blog by Vishal Gandhi',
  url: 'https://ivishalgandhi.github.io',
  baseUrl: '/',
  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',
  // favicon: 'img/vishal.png',
  organizationName: 'ivishalgandhi', // Usually your GitHub org/user name.
  projectName: 'ivishalgandhi.github.io', // Usually your repo name.

  // Even if you don't use internalization, you can use this field to set useful
  // metadata like html lang. For example, if your site is Chinese, you may want
  // to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  themes: [
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      {
        hashed: true,
        indexDocs: false,
        indexBlog: true,
        blogRouteBasePath: "/"
      },
    ],
  ],

  presets: [


    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        
        googleAnalytics: {
          trackingID: 'G-QTSVXZQKSV',
          anonymizeIP: true,
        }, 
        
        docs: false,//{
        //   sidebarPath: require.resolve('./sidebars.js'),
        //   // Please change this to your repo.
        //   // Remove this to remove the "edit this page" links.
        //   // editUrl:
        //   //   'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        // },
        blog: {
          // routeBasePath: '/', // Set this value to '/'.
          blogSidebarTitle: 'All posts',
          path: './blog',
          routeBasePath: '/',
          blogSidebarCount: 'ALL',
          showReadingTime: true,
          remarkPlugins: [require('mdx-mermaid')],          
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          // editUrl:
          //   'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        },
        theme: {
          customCss: require.resolve('./src/css/custom.css'),
        },
      }),
      
    ],
    
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      navbar: {
        title: 'The Data Column',
        logo: {
          alt: 'logo',
          src: 'img/vishal.png',
        },
        items: [
          // {
          //   type: 'doc',
          //   docId: 'intro',
          //   position: 'left',
          //   label: 'About',
          // },
          
          { to: 'about', label: 'About', position: 'left' }, 
          {
            href: 'https://github.com/ivishalgandhi',
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        style: 'dark',
        copyright: `Copyright © ${new Date().getFullYear()} Vishal Gandhi. Built with Docusaurus.`,
      },
      prism: {
        theme: lightCodeTheme,
        darkTheme: darkCodeTheme,
        additionalLanguages: ['powershell', 'csharp', 'docker', 'bicep'],
      },
    }),

};

module.exports = config;
