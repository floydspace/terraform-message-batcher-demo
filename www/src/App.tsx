import { gql } from 'graphql-tag'
import { useEffect, useRef, useState } from 'react'
import { useLazyQuery, useMutation, useSubscription } from 'react-apollo'

const BATCHES = gql`
  query batches {
    batches {
      criteria
      messages
    }
  }
`

const BATCH_CREATE = gql`
  mutation batchCreate($message: String!) {
    batchCreate(criteria: "batch", message: $message) {
      criteria
      messages
    }
  }
`

const BATCH_SUBSCRIPTION = gql`
  subscription batchReleased {
    batchReleased(criteria: "batch") {
      criteria
      messages
    }
  }
`

export default () => {
  const [batchList, { data, refetch }] = useLazyQuery(BATCHES)
  const [batchCreate] = useMutation(BATCH_CREATE)
  const { data: event } = useSubscription(BATCH_SUBSCRIPTION)
  const [message, setMessage] = useState({ value: '' })
  const [messageBatch, setMessageBatch] = useState([])
  const btnRef = useRef<HTMLInputElement>(null)

  useEffect(() => batchList(), [])
  useEffect(() => {
    if (event) {
      ;(async () => {
        await refetch?.()

        setMessageBatch(event?.batchReleased?.messages ?? [])
      })()
    }
  }, [event])

  const onCreate = async () => {
    await batchCreate({ variables: { message: message.value } })

    setMessage({ value: '' })

    await refetch?.()
  }

  const onEnterPress = ({ key }) => {
    if (key === 'Enter') {
      btnRef.current?.click()
    }
  }

  return (
    <div>
      <input
        value={message.value}
        onChange={({ target }) => setMessage({ value: target.value })}
        onKeyPress={onEnterPress}
      />
      <button ref={btnRef} onClick={onCreate}>
        Send Message
      </button>
      {data?.batches?.[0]?.messages?.map((m, i) => (
        <div key={i}>{m}</div>
      ))}
      <div style={{ color: 'red' }}>
        {messageBatch.map((m, i) => (
          <div key={i}>{m}</div>
        ))}
      </div>
    </div>
  )
}
