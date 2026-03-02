<script lang="ts">
  import { goto } from '$app/navigation';
  import { supabase } from '$lib/supabase';

  let title = '';
  let hostName = '';
  let isSubmitting = false;
  let errorMessage = '';

  const generateCode = () => Math.random().toString(36).substring(2, 8).toUpperCase();

  const createEvent = async () => {
    errorMessage = '';
    isSubmitting = true;

    try {
      let attempts = 0;
      let createdCode = '';

      while (attempts < 5) {
        const code = generateCode();

        const { error } = await supabase.from('events').insert({
          title: title.trim(),
          host_name: hostName.trim(),
          code,
          status: 'waiting'
        });

        if (!error) {
          createdCode = code;
          break;
        }

        if (error.code !== '23505') {
          throw error;
        }

        attempts += 1;
      }

      if (!createdCode) {
        throw new Error('Could not generate a unique event code. Try again.');
      }

      await goto(`/event/${createdCode}`);
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to create event.';
    } finally {
      isSubmitting = false;
    }
  };
</script>

<main class="page-shell">
  <div class="page-wrap">
    <div class="mx-auto max-w-xl neon-panel p-8">
      <p class="neon-kicker">Host Setup</p>
      <h1 class="theme-text mt-2 neon-heading">Create Event</h1>
      <p class="mt-2 text-sm muted-text">Set up your Q&amp;A room and share the code with attendees.</p>

    <form
      class="mt-6 space-y-4"
      onsubmit={(event) => {
        event.preventDefault();
        void createEvent();
      }}
    >
      <div>
        <label class="field-label" for="title">Event title</label>
        <input
          id="title"
          type="text"
          required
          maxlength="120"
          bind:value={title}
          class="field-input"
          placeholder="Weekly Product AMA"
        />
      </div>

      <div>
        <label class="field-label" for="host">Host name</label>
        <input
          id="host"
          type="text"
          required
          maxlength="60"
          bind:value={hostName}
          class="field-input"
          placeholder="Alex"
        />
      </div>

      {#if errorMessage}
        <p class="alert-error">{errorMessage}</p>
      {/if}

      <button
        type="submit"
        disabled={isSubmitting}
        class="btn-secondary w-full"
      >
        {isSubmitting ? 'Creating...' : 'Create Event'}
      </button>
    </form>

    <a href="/" class="theme-link mt-5 inline-flex text-sm font-medium transition hover:opacity-80">Back to home</a>
    </div>
  </div>
</main>