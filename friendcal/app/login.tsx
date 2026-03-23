import { useState } from 'react'
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native'
import { supabase } from '../lib/supabase'

export default function LoginScreen() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [mode, setMode] = useState<'login' | 'signup'>('login')

  async function handleSubmit() {
    if (!email || !password) {
      Alert.alert('Please enter your email and password.')
      return
    }

    setLoading(true)

    if (mode === 'signup') {
      const { error } = await supabase.auth.signUp({ email, password })
      if (error) {
        Alert.alert('Sign up failed', error.message)
      } else {
        Alert.alert('Check your email', 'We sent you a confirmation link.')
      }
    } else {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) {
        Alert.alert('Login failed', error.message)
      }
    }

    setLoading(false)
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <Text style={styles.title}>FriendCal</Text>
      <Text style={styles.subtitle}>A calendar for your crew</Text>

      <TextInput
        style={styles.input}
        placeholder="Email"
        placeholderTextColor="#999"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        keyboardType="email-address"
      />

      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#999"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
      />

      <TouchableOpacity style={styles.button} onPress={handleSubmit} disabled={loading}>
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>{mode === 'login' ? 'Log in' : 'Sign up'}</Text>
        )}
      </TouchableOpacity>

      <TouchableOpacity onPress={() => setMode(mode === 'login' ? 'signup' : 'login')}>
        <Text style={styles.switchText}>
          {mode === 'login' ? "Don't have an account? Sign up" : 'Already have an account? Log in'}
        </Text>
      </TouchableOpacity>
    </KeyboardAvoidingView>
  )
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 24,
  },
  title: {
    fontSize: 40,
    fontWeight: '700',
    marginBottom: 8,
    color: '#1a1a1a',
  },
  subtitle: {
    fontSize: 16,
    color: '#666',
    marginBottom: 48,
  },
  input: {
    width: '100%',
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    marginBottom: 12,
    color: '#1a1a1a',
  },
  button: {
    backgroundColor: '#4F46E5',
    paddingVertical: 14,
    borderRadius: 8,
    width: '100%',
    alignItems: 'center',
    marginTop: 4,
    marginBottom: 16,
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  switchText: {
    color: '#4F46E5',
    fontSize: 14,
  },
})
