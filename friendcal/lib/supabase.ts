import 'react-native-url-polyfill/auto'
import AsyncStorage from '@react-native-async-storage/async-storage'
import { createClient } from '@supabase/supabase-js'

// 👇 Replace these with your actual values from Supabase Dashboard > Project Settings > API
const SUPABASE_URL = 'https://dyvedikqpbbpzibvolpn.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_AkTWfpL8smndnExz5ubEzQ_Rr68ah0a'

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
})
