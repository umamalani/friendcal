import { useEffect, useState } from 'react'
import { Stack, router, SplashScreen } from 'expo-router'
import { Session } from '@supabase/supabase-js'
import { supabase } from '../lib/supabase'

SplashScreen.preventAutoHideAsync()

export default function RootLayout() {
  const [session, setSession] = useState<Session | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  useEffect(() => {
    if (loading) return
    SplashScreen.hideAsync()
    if (session) {
      router.replace('/(tabs)')
    } else {
      router.replace('/login')
    }
  }, [session, loading])

  return (
    <Stack>
      <Stack.Screen name="login" options={{ headerShown: false }} />
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
    </Stack>
  )
}
