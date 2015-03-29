---
type: blog-post
title: Redirecting HTTP to HTTPS in Spring Boot
date: 2015-03-25
tags: java, spring, spring boot, tomcat, security, quick tips
---
When using the embedded Tomcat server with Spring Boot, by default you choose either HTTP or HTTPS. But sometimes you want to allow users to come in through HTTP and then redirect them to HTTPS.

Spring Boot supports this. It would be nice if you could do the whole thing through `application.properties` configuration, but currently that's not possible. You can do one connector using configuration, but you have to do the other one programmatically. The reference documentation recommends doing the HTTPS connector using config since HTTPS configuration is more complicated than HTTP:

> Using configuration like the example above means the application will no longer support plain HTTP connector at port 8080. Spring Boot doesn’t support the configuration of both an HTTP connector and an HTTPS connector via `application.properties`. If you want to have both then you’ll need to configure one of them programmatically. It’s recommended to use `application.properties` to configure HTTPS as the HTTP connector is the easier of the two to configure programmatically. See the [spring-boot-sample-tomcat-multi-connectors](http://github.com/spring-projects/spring-boot/tree/master/spring-boot-samples/spring-boot-sample-tomcat-multi-connectors) sample project for an example.

Strangely (given the recommendation), the sample project does the HTTPS connector programmatically. But here we'll follow the recommendation.

## Step 1. Configure HTTPS using application.yml

I'm using `application.yml` instead of `application.properties` just because I prefer it, but it's easy to translate back and forth.

~~~ yaml
server:
  port: 8443
  ssl:
    key-store: classpath:keystore.jks
    key-store-password: s0m3p@$$word
~~~

This simple configuration sets up your Tomcat HTTPS/8443 connector. Of course you need to create the keystore, import the cert and put the keystore on the classpath.

## Step 2. Configure HTTP programmatically

Now we create the Tomcat HTTP/8080 connector programmatically:

~~~ java
package com.williewheeler.myapp;

import org.apache.catalina.Context;
import org.apache.catalina.connector.Connector;
import org.apache.tomcat.util.descriptor.web.SecurityCollection;
import org.apache.tomcat.util.descriptor.web.SecurityConstraint;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.web.HttpMessageConvertersAutoConfiguration;
import org.springframework.boot.context.embedded.EmbeddedServletContainerFactory;
import org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedServletContainerFactory;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableAutoConfiguration
@EnableConfigurationProperties
public class MyApp {
  
  public static void main(String[] args) throws Exception {
    SpringApplication.run(MyApp.class, args);
  }

  @Bean
  public EmbeddedServletContainerFactory servletContainer() {
    TomcatEmbeddedServletContainerFactory tomcat =
      new TomcatEmbeddedServletContainerFactory() {
      
        @Override
        protected void postProcessContext(Context context) {
          SecurityConstraint securityConstraint = new SecurityConstraint();
          securityConstraint.setUserConstraint("CONFIDENTIAL");
          SecurityCollection collection = new SecurityCollection();
          collection.addPattern("/*");
          securityConstraint.addCollection(collection);
          context.addConstraint(securityConstraint);
        }
      };
    tomcat.addAdditionalTomcatConnectors(createHttpConnector());
    return tomcat;
  }
  
  private Connector createHttpConnector() {
    Connector connector =
      new Connector("org.apache.coyote.http11.Http11NioProtocol");
    connector.setScheme("http");
    connector.setSecure(false);
    connector.setPort(8080);
    connector.setRedirectPort(8443);
    return connector;
  }

  // Other beans...
}
~~~

Now when you go to **http://localhost:8080**, Tomcat will automatically redirect you to **https://localhost:8443**.

## References

- [StackOverflow question](http://stackoverflow.com/questions/26655875/spring-boot-redirect-http-to-https)
- [Spring Boot Reference Docs](http://docs.spring.io/spring-boot/docs/current-SNAPSHOT/reference/htmlsingle/#howto-configure-ssl) - the links change pretty often, so you may have to Google for the blockquote I included above.
