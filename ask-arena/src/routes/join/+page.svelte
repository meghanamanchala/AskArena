<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let enteredCode = '';
  let userName = '';
  let isJoining = false;
  let errorMessage = '';

  const joinEvent = async () => {
    isJoining = true;
    errorMessage = '';

    try {
      const normalizedCode = enteredCode.trim().toUpperCase();

      const { data, error } = await supabase
        .from('events')
        .select('id, code')
        .eq('code', normalizedCode)
        .maybeSingle();

      if (error) {
        throw error;
      }

      if (!data) {
        errorMessage = 'Event code not found.';
        return;
      }

      const nameParam = encodeURIComponent(userName.trim());
      await goto(`/event/${normalizedCode}/attendee?name=${nameParam}`);
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to join event.';
    } finally {
      isJoining = false;
    }
  };
</script>

<main class="page-shell">
  <div class="page-wrap">
    <div class="mx-auto max-w-xl neon-panel p-8">
    <p class="neon-kicker">Attendee Access</p>
    <h1 class="theme-text mt-2 neon-heading">Join Event</h1>
    <p class="mt-2 text-sm muted-text">Enter your event code and name to join the live Q&amp;A.</p>

    <form
      class="mt-6 space-y-4"
      onsubmit={(event) => {
        event.preventDefault();
        void joinEvent();
      }}
    >
      <div>
        <label class="field-label" for="code">Event code</label>
        <input
          id="code"
          type="text"
          required
          maxlength="6"
          bind:value={enteredCode}
          class="field-input uppercase"
          placeholder="A1B2C3"
        />
      </div>

      <div>
        <label class="field-label" for="name">Your name</label>
        <input
          id="name"
          type="text"
          required
          maxlength="60"
          bind:value={userName}
          class="field-input"
          placeholder="Jordan"
        />
      </div>

      {#if errorMessage}
        <p class="alert-error">{errorMessage}</p>
      {/if}

      <button
        type="submit"
        disabled={isJoining}
        class="btn-primary w-full"
      >
        {isJoining ? 'Joining...' : 'Join Event'}
      </button>
    </form>

    <a href="/" class="theme-link mt-5 inline-flex text-sm font-medium transition hover:opacity-80">Back to home</a>
    </div>
  </div>
</main>