import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Head from '@docusaurus/Head';
import styles from './styles.module.css';

const features = [
  {
    title: 'What is this?',
    description: (
      <>
        <p>
          The Data Column is attempt to share my learnings with the world and the technology enthusiasts.
        </p>
        <p>
          As I attempt to explore FOSS and new technologies, I would also like to help those who are on a similar journey.
        </p>
        <p>
          Learn about NoSQL, Containers, Reverse Proxy, Docker, Kubernetes, and more here on my <a href="https://vishalgandhi.in">blog</a>.
        </p>
      
      </>
    ),
  },
  {
    title: 'What do I do?',
    description: (
      <>
        <p>
          I have been into multiple areas of software engineering, software support and database technologies for two decades. 
        </p>
        <p>
          Started my journey in traditional software. In the recent years I am fascinated by the FOSS and FOSS way of software development.
        </p>
        <p>
          I believe that if there is a code develop by someone, there was a business problem that triggered the need. I love to reproduce complex business problems and solve them using FOSS in my free time. 
        </p>
      </>
    ),
  },
  {
    title: 'Who am I?',
    description: (
      <>
        <p>
          Born and brought up in India, I enjoy reading books, finding ways to be more productive and creative. I believe in DRY (Dont Repeat Yourself) principle and love to automate the routine things. 
        </p>
        <p>
          My other passions includes cycling and running. My life experience changed when i transformed myself. During weekends, love to cook and try new cuisines.
        </p>
        <p>
          I have two lovely children who add joy to living each day. 
        </p>
      </>
    ),
  },
];

function Feature(
  /** @type {{ imageUrl?: string, title: String, description: JSX.Element }} */ {
    imageUrl,
    title,
    description,
  }
) {
  const imgUrl = useBaseUrl(imageUrl);
  return (
    <div className={clsx('col col--4', styles.feature)}>
      {imgUrl && (
        <div className="text--center">
          <img className={styles.featureImage} src={imgUrl} alt={title} />
        </div>
      )}
      <h3>{title}</h3>
      {description}
    </div>
  );
}

function About() {
  const imgUrl = useBaseUrl('img/vishal.png');
  const context = useDocusaurusContext();
  const { siteConfig = { title: '', tagline: '' } } = context;

  // details on structured data support: https://developers.google.com/search/docs/data-types/article#non-amp
  // and https://schema.org/Person
  const personStructuredData = {
    '@context': 'http://www.schema.org',
    '@type': 'Person',
    name: 'Vishal Gandhi',
    alternateName: 'Vishal Gandhi',
    description: '',
    url: 'https://vishalgandhi.in',
    image: 'https://vishalgandhi.in/img/vishal.png',
    address: {
      '@type': 'PostalAddress',
      streetAddress: '',
      addressLocality: 'Hyderabad',
      addressCountry: 'India',
    },
    email: 'igandhivishal@gmail.com',
    birthPlace: '',
    sameAs: [
      'https://twitter.com/ivishalgandhi/',
      'https://github.com/ivishalgandhi',
      'https://stackoverflow.com/users/8477466/vishal',
    ],
  };

  return (
    <>
      <Head>
        <script type="application/ld+json">
          {JSON.stringify(personStructuredData)}
        </script>
      </Head>

      <Layout
        title={`About ${siteConfig.title}`}
        description={`What is ${siteConfig.title}`}
      >
        <header className={clsx('hero hero--primary', styles.heroBanner)}>
          <div className="container">
            <h1 className="hero__title">{siteConfig.title}</h1>
            <div className="text--center">
              <img
                src={imgUrl}
                className={styles.profileImage}
                alt="Vishal Gandhi profile picture"
              />
            </div>
            <p className="hero__subtitle">{siteConfig.tagline}</p>
          </div>
        </header>
        <main>
          {features && features.length > 0 && (
            <section className={styles.features}>
              <div className="container">
                <div className="row">
                  {features.map((props, idx) => (
                    <Feature
                      key={idx}
                      title={props.title}
                      description={props.description}
                    />
                  ))}
                </div>
              </div>
            </section>
          )}
        </main>
      </Layout>
    </>
  );
}

export default About;