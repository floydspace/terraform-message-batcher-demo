import {
  ApolloClient,
  ApolloProvider,
  HttpLink,
  InMemoryCache,
} from "@apollo/client";
import { setContext } from "@apollo/link-context";

import config from "./config.json";

const ApolloWrapper = ({ children }) => {
  const httpLink = new HttpLink({
    uri: `${config.apiUrl}/graphql`,
  });

  const authLink = setContext((_, { headers, ...rest }) => {
    return {
      ...rest,
      headers: {
        ...headers,
        "x-api-key": config.apiKey,
      },
    };
  });

  const client = new ApolloClient({
    cache: new InMemoryCache(),
    link: authLink.concat(httpLink),
  });

  return <ApolloProvider client={client}>{children}</ApolloProvider>;
};

export default ApolloWrapper;
