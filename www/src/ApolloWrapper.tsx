import { InMemoryCache } from 'apollo-cache-inmemory'
import { ApolloClient } from 'apollo-client'
import { ApolloLink } from 'apollo-link'
import { AUTH_TYPE } from 'aws-appsync'
import { AuthOptions, createAuthLink } from 'aws-appsync-auth-link'
import { createSubscriptionHandshakeLink } from 'aws-appsync-subscription-link'
import { FC } from 'react'
import { ApolloProvider } from 'react-apollo'

import config from './config.json'

const ApolloWrapper: FC = ({ children }) => {
  const url = config.apiUrl
  const [, , region] = config.apiUrl.split('.')
  const auth: AuthOptions = {
    type: AUTH_TYPE.API_KEY,
    apiKey: config.apiKey,
  }

  const link = ApolloLink.from([
    createAuthLink({ url, region, auth }),
    createSubscriptionHandshakeLink({ url, region, auth }),
  ])

  const client = new ApolloClient({
    cache: new InMemoryCache(),
    link,
  })

  return <ApolloProvider client={client}>{children}</ApolloProvider>
}

export default ApolloWrapper
