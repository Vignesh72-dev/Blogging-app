package com.example.blog.controller;

import com.example.blog.model.Post;
import com.example.blog.repository.PostRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
public class PostController {

    @Autowired
    private PostRepository postRepository;

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("posts", postRepository.findAll());
        return "home";
    }

    @GetMapping("/posts/new")
    public String newPostForm(Model model) {
        model.addAttribute("post", new Post());
        return "add-post";
    }

    @PostMapping("/posts")
    public String createPost(@ModelAttribute Post post) {
        postRepository.save(post);
        return "redirect:/";
    }

    @GetMapping("/posts/{id}/edit")
    public String editPostForm(@PathVariable Long id, Model model) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Invalid post id: " + id));
        model.addAttribute("post", post);
        return "edit-post";
    }

    @PostMapping("/posts/{id}")
    public String updatePost(@PathVariable Long id, @ModelAttribute Post post) {
        post.setId(id);
        postRepository.save(post);
        return "redirect:/";
    }

    @PostMapping("/posts/{id}/delete")
    public String deletePost(@PathVariable Long id) {
        postRepository.deleteById(id);
        return "redirect:/";
    }
}
